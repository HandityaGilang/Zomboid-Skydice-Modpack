--
-- Dead Man's Dossier — Server Module
-- Handles dossier assembly, zombie death drops, proximity rewards.
-- All state mutations happen server-side for MP authority.
--

require "deadmansdossier_shared"

-- Project Zomboid loads media/lua/server/ on MULTIPLAYER CLIENTS as well as on the
-- server: GameLoadingState calls LuaManager.LoadDirBase("server") with no client
-- guard. Without this early return every client also registers OnZombieDead (which
-- itself fires client-side -- vanilla guards its own loot with `if (!GameClient.client)
-- DoZombieInventory()` and then triggers the event unguarded), rolls its own drop
-- chance, and calls sq:AddWorldInventoryItem locally.
--
-- Before 42.20 that client-spawned item was pushed to the server by
-- `if (GameClient.client) obj.transmitCompleteItemToServer();` inside
-- IsoGridSquare.AddWorldInventoryItem. 42.20 deleted that branch, so the page now
-- exists ONLY on that client. Picking it up is a server-validated transaction keyed
-- by InventoryItem.id (ContainerID.WorldObject); the server can't find the id in
-- sq.getWorldObjects(), TransactionManager.isConsistent returns 1, and the transfer
-- is rejected -- a page you can see forever and never pick up.
--
-- isClient() is false on a dedicated server, on the Host & Play coop server, and in
-- singleplayer, so the mod still runs everywhere it is supposed to.
if isClient() then return end

local TAG = "[DeadMansDossier]"

print(TAG .. " Server module loaded")

-- ---------------------------------------------------------------------------
-- Custom rewards config file
-- ---------------------------------------------------------------------------
local CONFIG_FILE = "DeadMansDossier_Rewards.cfg"
local TIER_ORDER = { "Police", "Military", "Medical", "Firefighter", "Ranger" }

local function generateDefaultConfig()
    local writer = getFileWriter(CONFIG_FILE, true, false)
    if not writer then
        print(TAG .. " WARNING: Could not create config file: " .. CONFIG_FILE)
        return
    end

    writer:write("# Dead Man's Dossier — Custom Rewards Configuration\n")
    writer:write("#\n")
    writer:write("# To use this file, enable 'Use Custom Rewards' in sandbox options.\n")
    writer:write("# The server must be restarted after editing this file.\n")
    writer:write("#\n")
    writer:write("# Format:\n")
    writer:write("#   [TierName]            — Section header (Police, Military, Medical, Firefighter, Ranger)\n")
    writer:write("#   Base.ItemName = 0.30  — Item type and drop chance (0.0 to 1.0)\n")
    writer:write("#   # comment             — Lines starting with # are ignored\n")
    writer:write("#\n")
    writer:write("# The RewardRarity sandbox multiplier is still applied on top of these chances.\n")
    writer:write("# Items from uninstalled mods are silently skipped (safe for cross-mod items).\n")
    writer:write("# To disable an item, delete the line or comment it out with #.\n")
    writer:write("# To add an item, add a new line under the appropriate tier: Base.ItemName = 0.50\n")
    writer:write("# Item types can be found in the PZ item browser or script files.\n")
    writer:write("#\n\n")

    for _, tierKey in ipairs(TIER_ORDER) do
        local rewards = DeadMansDossier.REWARDS[tierKey]
        if rewards then
            writer:write("[" .. tierKey .. "]\n")
            for _, reward in ipairs(rewards) do
                writer:write(reward.item .. " = " .. string.format("%.2f", reward.chance) .. "\n")
            end
            writer:write("\n")
        end
    end

    writer:close()
    print(TAG .. " Generated default config file: " .. CONFIG_FILE)
end

local function parseConfigFile()
    local reader = getFileReader(CONFIG_FILE, false)
    if not reader then
        print(TAG .. " Custom rewards config file not found: " .. CONFIG_FILE)
        return nil
    end

    local rewards = {}
    local currentTier = nil
    local lineNum = 0

    local line = reader:readLine()
    while line ~= nil do
        lineNum = lineNum + 1
        line = line:match("^%s*(.-)%s*$") or ""

        if line ~= "" and line:sub(1, 1) ~= "#" then
            local tier = line:match("^%[(%w+)%]$")
            if tier then
                if DeadMansDossier.TIERS[tier] then
                    currentTier = tier
                    if not rewards[tier] then
                        rewards[tier] = {}
                    end
                else
                    print(TAG .. " WARNING: Unknown tier '" .. tier .. "' in config line " .. lineNum .. " — skipping")
                    currentTier = nil
                end
            elseif currentTier then
                local item, chance = line:match("^([%w_%.]+)%s*=%s*([%d%.]+)$")
                if item and chance then
                    local chanceNum = tonumber(chance)
                    if chanceNum and chanceNum >= 0 and chanceNum <= 1 then
                        table.insert(rewards[currentTier], { item = item, chance = chanceNum })
                    else
                        print(TAG .. " WARNING: Invalid chance '" .. chance .. "' in config line " .. lineNum .. " — must be 0.0 to 1.0")
                    end
                else
                    print(TAG .. " WARNING: Could not parse config line " .. lineNum .. ": " .. line)
                end
            end
        end

        line = reader:readLine()
    end

    reader:close()
    return rewards
end

local function loadCustomRewards()
    -- Always generate default config if it doesn't exist
    local reader = getFileReader(CONFIG_FILE, false)
    if reader then
        reader:close()
    else
        generateDefaultConfig()
    end

    -- Only load custom rewards if sandbox option is enabled
    local useCustom = false
    if SandboxVars and SandboxVars.DeadMansDossier and SandboxVars.DeadMansDossier.UseCustomRewards then
        useCustom = SandboxVars.DeadMansDossier.UseCustomRewards
    end

    if not useCustom then
        print(TAG .. " Using default hardcoded rewards (UseCustomRewards is off)")
        return
    end

    print(TAG .. " Loading custom rewards from " .. CONFIG_FILE)
    local customRewards = parseConfigFile()
    if not customRewards then
        print(TAG .. " WARNING: Failed to load config file — using default rewards")
        return
    end

    local totalItems = 0
    for _, tierKey in ipairs(TIER_ORDER) do
        if customRewards[tierKey] and #customRewards[tierKey] > 0 then
            DeadMansDossier.REWARDS[tierKey] = customRewards[tierKey]
            print(TAG .. " Loaded " .. #customRewards[tierKey] .. " custom reward(s) for " .. tierKey)
            totalItems = totalItems + #customRewards[tierKey]
        elseif customRewards[tierKey] then
            print(TAG .. " WARNING: Tier " .. tierKey .. " has no items in config — keeping defaults")
        end
    end

    print(TAG .. " Custom rewards active: " .. totalItems .. " total items across configured tiers")
end

loadCustomRewards()

-- ---------------------------------------------------------------------------
-- Anti-spam cooldown tracker (username -> timestamp in ms)
-- ---------------------------------------------------------------------------
local lastAssembleAttempt = {}
local ASSEMBLE_COOLDOWN_MS = 5000

-- Drop chance multipliers indexed by DropChance sandbox enum value
local DROP_CHANCE_VALUES = {
    [1] = 0.30,  -- High
    [2] = 0.15,  -- Normal (default)
    [3] = 0.08,  -- Low
    [4] = 0.03,  -- Very Low
}

-- Reward rarity multipliers indexed by RewardRarity sandbox enum value
local REWARD_RARITY_VALUES = {
    [1] = 2.0,   -- Generous
    [2] = 1.0,   -- Normal (default)
    [3] = 0.5,   -- Scarce
    [4] = 0.1,   -- Minimal
}

-- ---------------------------------------------------------------------------
-- Helper: get player display name for logging
-- ---------------------------------------------------------------------------
local function playerName(player)
    return player:getDisplayName() or player:getUsername() or "survivor"
end

-- ---------------------------------------------------------------------------
-- Helper: get or create DMD mission data for a player
-- Uses GlobalModData (persists with world save) keyed by username,
-- instead of player:getModData() which is unreliable for server-side
-- persistence in multiplayer.
-- ---------------------------------------------------------------------------
local function getMissionStore()
    return ModData.getOrCreate("DeadMansDossier_Missions")
end

local function getMissions(player)
    local store = getMissionStore()
    local username = player:getUsername()
    if not store[username] then
        store[username] = {}
    end
    return store[username]
end

-- ---------------------------------------------------------------------------
-- Helper: check if player has any active missions
-- ---------------------------------------------------------------------------
local function hasAnyActiveMission(player)
    local missions = getMissions(player)
    for _, _ in pairs(missions) do
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Helper: get the proximity radius from sandbox options
-- ---------------------------------------------------------------------------
local function getProximityRadius()
    if SandboxVars and SandboxVars.DeadMansDossier and SandboxVars.DeadMansDossier.ProximityRadius then
        return SandboxVars.DeadMansDossier.ProximityRadius
    end
    return DeadMansDossier.PROXIMITY_RADIUS
end

-- ---------------------------------------------------------------------------
-- Assembly handler: validate pages, remove them, create dossier, assign stash
-- ---------------------------------------------------------------------------
local function handleAssemble(player, args)
    local tierKey = args.tierKey
    local tier = DeadMansDossier.TIERS[tierKey]
    if not tier then
        print(TAG .. " Invalid tier: " .. tostring(tierKey))
        return
    end

    -- Check for existing active mission for this tier
    local missions = getMissions(player)
    if missions[tierKey] then
        sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_ASSEMBLE_RESULT, {
            success = false,
            -- Send a KEY, not text: the client resolves it with getText() so each
            -- player sees their own locale rather than the server's.
            messageKey = "AlreadyActive",
        })
        return
    end

    -- Validate all pages are in player inventory (server authority)
    local inv = player:getInventory()
    for _, pageType in ipairs(tier.pages) do
        if not inv:containsTypeRecurse(pageType) then
            print(TAG .. " " .. playerName(player) .. " missing page: " .. pageType)
            sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_ASSEMBLE_RESULT, {
                success = false,
                messageKey = "MissingPages",
            })
            return
        end
    end

    -- Remove pages from inventory (server-side only).
    -- We do NOT use sendRemoveItemFromContainer here because it crashes the client
    -- with a ContainerID NullPointerException for items in deeply nested containers
    -- (e.g. page inside FirstAidKit inside DuffelBag). Instead, the client removes
    -- pages locally when it receives CMD_ASSEMBLE_RESULT with success=true.
    for _, pageType in ipairs(tier.pages) do
        local page = inv:getFirstTypeRecurse(pageType)
        if page then
            local pageContainer = page:getContainer() or inv
            print(TAG .. " Removing page: " .. pageType .. " from " .. tostring(pageContainer:getType()))
            pageContainer:Remove(page)
        else
            print(TAG .. " WARNING: getFirstTypeRecurse returned nil for: " .. pageType)
        end
    end

    -- Add completed dossier (with MP network sync)
    local dossier = instanceItem(tier.result)
    if dossier then
        inv:AddItem(dossier)
        sendAddItemToContainer(inv, dossier)
        print(TAG .. " Added dossier item: " .. tostring(dossier:getFullType()))
    else
        print(TAG .. " WARNING: instanceItem returned nil for: " .. tier.result)
    end

    -- Pick random stash location
    local stashIdx = ZombRand(#DeadMansDossier.STASH_LOCATIONS) + 1
    local stash = DeadMansDossier.STASH_LOCATIONS[stashIdx]

    -- Store mission in GlobalModData (persists with world save)
    missions[tierKey] = {
        stashX = stash.x,
        stashY = stash.y,
        stashZ = stash.z,
        stashLabel = stash.label,
    }

    print(TAG .. " " .. playerName(player) .. " assembled " .. tierKey
        .. " dossier. Stash: " .. stash.label .. " (" .. stash.x .. ", " .. stash.y .. ")")

    sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_ASSEMBLE_RESULT, {
        success = true,
        tierKey = tierKey,
        stashLabel = stash.label,
        stashX = stash.x,
        stashY = stash.y,
    })
end

-- ---------------------------------------------------------------------------
-- Proximity handler: check if player is near their active stash
-- Sends graduated distance hints when not within reward radius.
-- ---------------------------------------------------------------------------
local function handleProximity(player, args)
    local px = args.x or 0
    local py = args.y or 0
    local pz = args.z or 0
    local radius = getProximityRadius()
    local missions = getMissions(player)

    -- Diagnostic: log player position and mission count
    local missionCount = 0
    for _ in pairs(missions) do missionCount = missionCount + 1 end
    print(TAG .. " Proximity check: player=(" .. px .. ", " .. py .. ", " .. pz
        .. "), radius=" .. radius .. ", missions=" .. missionCount)

    if missionCount == 0 then
        print(TAG .. " WARNING: No active missions for " .. playerName(player) .. " — mission data may have been lost")
    end

    local closestDist = nil
    local closestTierKey = nil

    for tierKey, mission in pairs(missions) do
        -- Z-axis gate: must be within 1 floor of the stash
        local stashZ = mission.stashZ or 0
        if math.abs(pz - stashZ) > 1 then
            print(TAG .. " Proximity skip: tier=" .. tierKey .. ", player Z=" .. pz .. " vs stash Z=" .. stashZ)
        else
            local dx = px - mission.stashX
            local dy = py - mission.stashY
            local dist = math.sqrt(dx * dx + dy * dy)
            print(TAG .. " Proximity dist: tier=" .. tierKey .. ", stash=(" .. mission.stashX .. ", " .. mission.stashY
                .. "), dist=" .. string.format("%.1f", dist))

            if dist <= radius then
                -- Player is within reward radius — grant rewards
                print(TAG .. " " .. playerName(player) .. " reached stash for " .. tierKey
                    .. " (dist=" .. string.format("%.1f", dist) .. ")")

                -- Roll rewards and drop on the stash square
                local rewards = DeadMansDossier.REWARDS[tierKey]
                if rewards then
                    -- Apply reward rarity multiplier from sandbox settings
                    local rarityEnum = 2
                    if SandboxVars and SandboxVars.DeadMansDossier and SandboxVars.DeadMansDossier.RewardRarity then
                        rarityEnum = SandboxVars.DeadMansDossier.RewardRarity
                    end
                    local rarityMult = REWARD_RARITY_VALUES[rarityEnum] or 1.0

                    local sq = getCell():getGridSquare(mission.stashX, mission.stashY, mission.stashZ or 0)
                    local granted = 0
                    local failed = 0
                    if sq then
                        for _, reward in ipairs(rewards) do
                            local effectiveChance = math.min(reward.chance * rarityMult, 1.0)
                            local roll = ZombRand(100) / 100.0
                            if roll < effectiveChance then
                                -- AddWorldInventoryItem returns nil when the item type
                                -- doesn't exist (InventoryItemFactory.CreateItem returns
                                -- null and the square is left untouched). Counting the
                                -- attempt instead of the result is what let ~20 stale B41
                                -- item IDs sit in the reward tables unnoticed — the log
                                -- claimed drops that never happened.
                                if sq:AddWorldInventoryItem(reward.item, 0, 0, 0) then
                                    granted = granted + 1
                                else
                                    failed = failed + 1
                                    print(TAG .. " WARNING: reward item does not exist: " .. tostring(reward.item))
                                end
                            end
                        end
                        print(TAG .. " Dropped " .. granted .. " reward item(s)"
                            .. (failed > 0 and (" (" .. failed .. " FAILED — unknown item type)") or "")
                            .. " on ground at ("
                            .. mission.stashX .. ", " .. mission.stashY .. ") for " .. playerName(player))
                    else
                        print(TAG .. " WARNING: Could not get stash square at ("
                            .. mission.stashX .. ", " .. mission.stashY .. "), falling back to player inventory")
                        local inv = player:getInventory()
                        for _, reward in ipairs(rewards) do
                            local effectiveChance = math.min(reward.chance * rarityMult, 1.0)
                            local roll = ZombRand(100) / 100.0
                            if roll < effectiveChance then
                                local item = instanceItem(reward.item)
                                if item then
                                    inv:AddItem(item)
                                    sendAddItemToContainer(inv, item)
                                    granted = granted + 1
                                else
                                    failed = failed + 1
                                    print(TAG .. " WARNING: reward item does not exist: " .. tostring(reward.item))
                                end
                            end
                        end
                        print(TAG .. " Granted " .. granted .. " reward item(s) to inventory (fallback)"
                            .. (failed > 0 and (" (" .. failed .. " FAILED — unknown item type)") or ""))
                    end

                    -- Remove the completed dossier from inventory (server-side only).
                    -- Client removes locally when it receives CMD_REWARD_GRANTED.
                    local inv = player:getInventory()
                    local tier = DeadMansDossier.TIERS[tierKey]
                    local dossier = tier and inv:getFirstTypeRecurse(tier.result)
                    if dossier then
                        local dossierContainer = dossier:getContainer() or inv
                        print(TAG .. " Removing dossier: " .. tier.result .. " from " .. tostring(dossierContainer:getType()))
                        dossierContainer:Remove(dossier)
                    end
                end

                -- Clear this mission
                missions[tierKey] = nil

                local stillHasMissions = hasAnyActiveMission(player)

                -- Encode boolean as 1/0 for safe KahluaTable serialization
                sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_REWARD_GRANTED, {
                    tierKey = tierKey,
                    hasMoreMissions = stillHasMissions and 1 or 0,
                })

                -- Only process one stash per tick
                return
            end

            -- Track closest mission for hint
            if not closestDist or dist < closestDist then
                closestDist = dist
                closestTierKey = tierKey
            end
        end
    end

    -- No stash was in reward range — send graduated proximity hint
    if closestDist and closestTierKey then
        local band
        if closestDist < radius * 1.5 then
            band = "veryclose"
        elseif closestDist < radius * 2 then
            band = "warm"
        elseif closestDist < radius * 3 then
            band = "nearby"
        end

        if band then
            local closestMission = missions[closestTierKey]
            print(TAG .. " Proximity hint: tier=" .. closestTierKey .. ", dist=" .. string.format("%.1f", closestDist) .. ", band=" .. band)
            sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_PROXIMITY_HINT, {
                band = band,
                tierKey = closestTierKey,
                stashX = closestMission.stashX,
                stashY = closestMission.stashY,
                stashLabel = closestMission.stashLabel,
            })
            return
        end
    end

    -- No stash was close enough for any hint — include all active missions
    -- so the client can restore any missing map markers
    local missionList = {}
    for tierKey, mission in pairs(missions) do
        table.insert(missionList, {
            tierKey = tierKey,
            stashX = mission.stashX,
            stashY = mission.stashY,
            stashLabel = mission.stashLabel,
        })
    end
    if closestDist then
        print(TAG .. " Not close enough: closest tier=" .. tostring(closestTierKey) .. ", dist=" .. string.format("%.1f", closestDist) .. " (need <" .. radius .. ")")
    end
    sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_NOT_CLOSE, {
        missions = missionList,
    })
end

-- ---------------------------------------------------------------------------
-- Mission sync handler: send all active missions to a reconnecting client
-- ---------------------------------------------------------------------------
local function handleRequestMissions(player)
    local missions = getMissions(player)
    local missionList = {}
    for tierKey, mission in pairs(missions) do
        table.insert(missionList, {
            tierKey = tierKey,
            stashX = mission.stashX,
            stashY = mission.stashY,
            stashLabel = mission.stashLabel,
        })
    end
    print(TAG .. " Syncing " .. #missionList .. " mission(s) to " .. playerName(player))
    sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_SYNC_MISSIONS, {
        missions = missionList,
    })
end

-- ---------------------------------------------------------------------------
-- Abandon mission handler: remove dossier and clear mission data
-- ---------------------------------------------------------------------------
local function handleAbandonMission(player, args)
    local tierKey = args.tierKey
    local tier = DeadMansDossier.TIERS[tierKey]
    if not tier then
        print(TAG .. " AbandonMission: invalid tier " .. tostring(tierKey))
        return
    end

    -- Remove the completed dossier from inventory (server-side only)
    local inv = player:getInventory()
    local dossier = inv:getFirstTypeRecurse(tier.result)
    if dossier then
        local dossierContainer = dossier:getContainer() or inv
        print(TAG .. " AbandonMission: removing dossier " .. tier.result .. " from " .. tostring(dossierContainer:getType()))
        dossierContainer:Remove(dossier)
    end

    -- Clear mission data (may already be nil if orphaned after rollback)
    local missions = getMissions(player)
    local hadMission = missions[tierKey] ~= nil
    missions[tierKey] = nil

    if hadMission then
        print(TAG .. " " .. playerName(player) .. " abandoned " .. tierKey .. " mission")
    else
        print(TAG .. " " .. playerName(player) .. " abandoned orphaned " .. tierKey .. " dossier (no mission data)")
    end

    sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_ABANDON_RESULT, {
        success = true,
        tierKey = tierKey,
    })
end

-- ---------------------------------------------------------------------------
-- Player death handler: clear all missions for deceased player
-- PZ is permadeath — missions on the corpse are unrecoverable, so wipe them
-- to prevent the new character from being stuck with stale markers/blocks.
-- ---------------------------------------------------------------------------
local function onPlayerDeath(player)
    local username = player:getUsername()
    if not username then return end
    local store = getMissionStore()
    if not store[username] then return end
    local cleared = 0
    for _ in pairs(store[username]) do cleared = cleared + 1 end
    if cleared > 0 then
        store[username] = {}
        print(TAG .. " Cleared " .. cleared .. " mission(s) for deceased player: " .. username)
    end
end

-- ---------------------------------------------------------------------------
-- Client command dispatcher
-- ---------------------------------------------------------------------------
local function dispatchClientCommand(module, command, player, args)
    if module ~= DeadMansDossier.MOD_ID then return end

    -- PZ sends nil instead of an empty table — guard against it
    args = args or {}

    print(TAG .. " Received command: " .. tostring(command) .. " from player: " .. playerName(player))

    if command == DeadMansDossier.CMD_ASSEMBLE then
        -- Anti-spam cooldown
        local username = player:getUsername() or ""
        local now = getTimestampMs()
        if lastAssembleAttempt[username] and (now - lastAssembleAttempt[username]) < ASSEMBLE_COOLDOWN_MS then
            print(TAG .. " Rate limited Assemble from " .. playerName(player))
            return
        end
        lastAssembleAttempt[username] = now

        handleAssemble(player, args)

    elseif command == DeadMansDossier.CMD_CHECK_PROXIMITY then
        handleProximity(player, args)

    elseif command == DeadMansDossier.CMD_PLAYER_DIED then
        onPlayerDeath(player)

    elseif command == DeadMansDossier.CMD_ABANDON_MISSION then
        handleAbandonMission(player, args)

    elseif command == DeadMansDossier.CMD_REQUEST_MISSIONS then
        handleRequestMissions(player)

    elseif command == DeadMansDossier.CMD_CLEAR_TEST_DATA then
        -- Test-only: clear mission for a tier and reset anti-spam cooldown
        local tierKey = args.tierKey
        if tierKey then
            local missions = getMissions(player)
            missions[tierKey] = nil
        end
        local username = player:getUsername() or ""
        lastAssembleAttempt[username] = nil

    elseif command == DeadMansDossier.CMD_TEST_CHECK_DISTRIBUTIONS then
        -- Test-only: verify distribution injection happened correctly
        local procDist = ProceduralDistributions
        local missing = {}
        local expectedDists = {
            { tier = "Police",      names = {"PoliceStorageGuns","PoliceLockers","PoliceStorageOutfit","PoliceDesk","PoliceEvidence","PoliceFileBox","PoliceFilingCabinet"} },
            { tier = "Military",    names = {"ArmyHangarTools","ArmySurplusTools","ArmyHangarOutfit","ArmySurplusOutfit","ArmyStorageGuns","ArmyStorageOutfit","ArmyBunkerStorage","ArmyBunkerLockers"} },
            { tier = "Medical",     names = {"MedicalStorageDrugs","MedicalStorageTools","MedicalClinicDrugs","HospitalLockers"} },
            { tier = "Firefighter", names = {"FireDeptLockers","FireStorageOutfit"} },
            { tier = "Ranger",      names = {"RangerOutfit","RangerTools"} },
        }
        for _, entry in ipairs(expectedDists) do
            local tier = DeadMansDossier.TIERS[entry.tier]
            if tier then
                local firstPage = tier.pages[1]
                for _, distName in ipairs(entry.names) do
                    if not procDist or not procDist.list or not procDist.list[distName] then
                        table.insert(missing, distName .. " (table missing)")
                    else
                        local found = false
                        local items = procDist.list[distName].items
                        if items then
                            for i = 1, #items, 2 do
                                if items[i] == firstPage then
                                    found = true
                                    break
                                end
                            end
                        end
                        if not found then
                            table.insert(missing, distName .. " (pages not injected)")
                        end
                    end
                end
            end
        end
        local success = #missing == 0
        local details = table.concat(missing, "; ")
        print(TAG .. " TestCheckDistributions: success=" .. tostring(success)
            .. ", missing=" .. #missing .. (details ~= "" and (": " .. details) or ""))
        sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_TEST_DISTRIBUTIONS_RESULT, {
            success = success and 1 or 0,
            missingCount = #missing,
            details = details,
        })

    elseif command == DeadMansDossier.CMD_TEST_SIMULATE_DEATH then
        -- Test-only: invoke the same logic as onPlayerDeath + reset cooldown
        onPlayerDeath(player)
        local username = player:getUsername() or ""
        lastAssembleAttempt[username] = nil

    elseif command == DeadMansDossier.CMD_TEST_VERIFY_STASH then
        -- Test-only: simulate player at stash by calling proximity with stash coords
        local tierKey = args.tierKey
        local missions = getMissions(player)
        local mission = missions[tierKey]
        if mission then
            print(TAG .. " TestVerifyStash: simulating proximity for " .. tierKey
                .. " at (" .. mission.stashX .. ", " .. mission.stashY .. ")")
            handleProximity(player, {
                x = mission.stashX,
                y = mission.stashY,
                z = mission.stashZ or 0,
            })
        else
            print(TAG .. " TestVerifyStash: no active mission for " .. tostring(tierKey))
        end

    elseif command == DeadMansDossier.CMD_TEST_CUSTOM_REWARDS then
        -- Test-only: exercise config generation, parsing, and override logic
        local errors = {}

        -- Step 1: Generate default config file
        generateDefaultConfig()
        local reader = getFileReader(CONFIG_FILE, false)
        if not reader then
            table.insert(errors, "default config file was not created")
        else
            reader:close()
        end

        -- Step 2: Parse the default config and verify all tiers are present
        local defaultParsed = parseConfigFile()
        if not defaultParsed then
            table.insert(errors, "parseConfigFile returned nil for default config")
        else
            for _, tk in ipairs(TIER_ORDER) do
                if not defaultParsed[tk] or #defaultParsed[tk] == 0 then
                    table.insert(errors, "default config missing tier: " .. tk)
                end
            end
            -- Verify Police has the right item count
            local originalPoliceCount = DeadMansDossier.REWARDS.Police and #DeadMansDossier.REWARDS.Police or 0
            if defaultParsed.Police and #defaultParsed.Police ~= originalPoliceCount then
                table.insert(errors, "default Police count mismatch: parsed=" .. #defaultParsed.Police .. " expected=" .. originalPoliceCount)
            end
        end

        -- Step 3: Write a test config with known values and parse it
        local testWriter = getFileWriter(CONFIG_FILE, true, false)
        if testWriter then
            testWriter:write("# Test config\n")
            testWriter:write("[Police]\n")
            testWriter:write("Base.Axe = 1.00\n")
            testWriter:write("Base.Hammer = 0.50\n")
            testWriter:write("# Base.Commented = 0.30\n")
            testWriter:write("\n")
            testWriter:write("[Military]\n")
            testWriter:write("Base.Shotgun = 0.75\n")
            testWriter:write("invalid line without equals\n")
            testWriter:write("Base.BadChance = 2.50\n")
            testWriter:write("\n")
            testWriter:write("[FakeTier]\n")
            testWriter:write("Base.Nope = 0.10\n")
            testWriter:close()

            local testParsed = parseConfigFile()
            if not testParsed then
                table.insert(errors, "parseConfigFile returned nil for test config")
            else
                -- Police: 2 items (comment should be skipped)
                if not testParsed.Police or #testParsed.Police ~= 2 then
                    table.insert(errors, "test Police count: expected 2, got " .. (testParsed.Police and #testParsed.Police or "nil"))
                else
                    if testParsed.Police[1].item ~= "Base.Axe" or testParsed.Police[1].chance ~= 1.0 then
                        table.insert(errors, "test Police[1] mismatch")
                    end
                    if testParsed.Police[2].item ~= "Base.Hammer" or testParsed.Police[2].chance ~= 0.5 then
                        table.insert(errors, "test Police[2] mismatch")
                    end
                end
                -- Military: 1 item (invalid line and bad chance should be skipped)
                if not testParsed.Military or #testParsed.Military ~= 1 then
                    table.insert(errors, "test Military count: expected 1, got " .. (testParsed.Military and #testParsed.Military or "nil"))
                end
                -- FakeTier should not appear (unknown tier)
                if testParsed.FakeTier then
                    table.insert(errors, "FakeTier should not be parsed")
                end
                -- Unparsed tiers should be absent
                if testParsed.Medical then
                    table.insert(errors, "Medical should not be in test config")
                end
            end
        else
            table.insert(errors, "could not write test config file")
        end

        -- Step 4: Test override logic — temporarily override and verify
        local origPolice = DeadMansDossier.REWARDS.Police
        local testRewards = { { item = "Base.TestItem", chance = 1.0 } }
        DeadMansDossier.REWARDS.Police = testRewards
        local overrideOk = DeadMansDossier.REWARDS.Police[1].item == "Base.TestItem"
        DeadMansDossier.REWARDS.Police = origPolice
        if not overrideOk then
            table.insert(errors, "REWARDS override did not take effect")
        end

        -- Step 5: Restore default config file for future use
        generateDefaultConfig()

        local success = #errors == 0
        local details = table.concat(errors, "; ")
        print(TAG .. " TestCustomRewards: success=" .. tostring(success)
            .. (details ~= "" and (", errors: " .. details) or ""))
        sendServerCommand(player, DeadMansDossier.MOD_ID, DeadMansDossier.CMD_TEST_CUSTOM_REWARDS_RESULT, {
            success = success and 1 or 0,
            errorCount = #errors,
            details = details,
        })
    end
end

--- Every handler mutates authoritative state (mission store, player inventory)
--- before it replies. An uncaught error would leave that state half-applied AND
--- abort the event for the rest of the call, so keep failures contained and loud.
local function onClientCommand(module, command, player, args)
    if module ~= DeadMansDossier.MOD_ID then return end
    if not player then
        print(TAG .. " Ignoring " .. tostring(command) .. " with no player")
        return
    end
    local ok, err = pcall(dispatchClientCommand, module, command, player, args)
    if not ok then
        print(TAG .. " ERROR in " .. tostring(command) .. ": " .. tostring(err))
    end
end

Events.OnClientCommand.Add(onClientCommand)

-- ---------------------------------------------------------------------------
-- Zombie death handler: drop pages from police/military zombies
-- ---------------------------------------------------------------------------
local function onZombieDead(zombie)
    if not zombie then return end

    local ok, outfitName = pcall(function() return zombie:getOutfitName() end)
    if not ok or not outfitName then return end

    local tierKey = DeadMansDossier.OUTFIT_MAP[outfitName]
    if not tierKey then return end

    -- Get per-tier drop chance from sandbox settings
    local dropEnum = 2
    if SandboxVars and SandboxVars.DeadMansDossier then
        local tierOption = SandboxVars.DeadMansDossier["DropChance_" .. tierKey]
        if tierOption then
            dropEnum = tierOption
        end
    end
    local dropChance = DROP_CHANCE_VALUES[dropEnum] or 0.15

    -- Roll for drop
    local roll = ZombRand(1000) / 1000.0
    if roll >= dropChance then
        print(TAG .. " Zombie killed with outfit: " .. outfitName .. ", tier: " .. tierKey
            .. ", roll: " .. string.format("%.3f", roll) .. " vs chance: " .. string.format("%.3f", dropChance) .. " — MISS")
        return
    end

    -- Pick a random page from this tier
    local tier = DeadMansDossier.TIERS[tierKey]
    if not tier then return end

    local pageIdx = ZombRand(#tier.pages) + 1
    local pageType = tier.pages[pageIdx]

    -- Drop on the ground at zombie's position
    local sq = zombie:getCurrentSquare()
    if not sq then
        print(TAG .. " Zombie getCurrentSquare() returned nil for outfit: " .. outfitName .. ", cannot drop page")
        return
    end
    sq:AddWorldInventoryItem(pageType, 0, 0, 0)
    print(TAG .. " Dropped " .. pageType .. " from " .. outfitName .. " zombie"
        .. " (roll: " .. string.format("%.3f", roll) .. " vs chance: " .. string.format("%.3f", dropChance) .. ")")
end

Events.OnZombieDead.Add(onZombieDead)
