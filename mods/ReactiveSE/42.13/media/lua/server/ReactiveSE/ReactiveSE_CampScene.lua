--//////////////////////////////////////////////////--
--    Reactive Sound Events - Camp Scene
--    Adds camp structures (tents, campfire) to scenes
--    in non-urban areas. Wraps the underlying scene logic.
--//////////////////////////////////////////////////--

if isClient() and not isServer() then return end

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local CombatScene = require "ReactiveSE/ReactiveSE_CombatScene"
local WorldTier = require "ReactiveSE/ReactiveSE_WorldTier"

local ReactiveSE_CampScene = {}

--//////////////////////////////////////////////////--
--          Configuration                         --
--//////////////////////////////////////////////////--

-- Possible meat items to spawn in campfire
local CAMPFIRE_MEAT_ITEMS = {
    "Base.Rabbitmeat",
    "Base.FrogMeat",
    "Base.Smallanimalmeat",
    "Base.Smallbirdmeat",
    "Base.FishFillet",
    "Base.DeadRat",
    "Base.Cockroach",
    "Base.ChickenFillet",
    "Base.DeadRatBaby",
    "Base.TurkeyFillet",
    "Base.MuttonChop"
}

-- Bag types for meat storage
local CAMP_BAG_TYPES = {
    "Base.Bag_HideSack",
    "Base.EmptySandbag",
    "Base.Tacklebox"
}

-- Pending bags waiting for container initialization
local pendingBags = {}

--//////////////////////////////////////////////////--
--          OnContainerUpdate Handler             --
--//////////////////////////////////////////////////--

---Handles container update event to add items to pending bags
---@param object InventoryItem|InventoryContainer The bag object passed from triggerEvent
local function OnContainerUpdate(object)
    if not object then return end
    if #pendingBags == 0 then return end

    -- Check pending bags
    for i = #pendingBags, 1, -1 do
        local pending = pendingBags[i]
        local bag = pending.bag

        Utils.LogInfo("  [CampScene] Checking pending bag " .. i .. ": " .. tostring(bag:getFullType()))

        local objIsContainer = instanceof(object, "InventoryContainer")
        local bagIsContainer = instanceof(bag, "InventoryContainer")
        Utils.LogInfo("  [CampScene] object is InventoryContainer: " ..
            tostring(objIsContainer) .. ", bag is InventoryContainer: " .. tostring(bagIsContainer))

        if objIsContainer and bagIsContainer then
            local objectType = object:getFullType()
            local bagType = bag:getFullType()
            Utils.LogInfo("  [CampScene] Comparing types: object=" ..
                tostring(objectType) .. ", bag=" .. tostring(bagType))

            if objectType == bagType then
                local container = object:getInventory()
                Utils.LogInfo("  [CampScene] Got container: " .. tostring(container))

                if container then
                    for j = 1, pending.count do
                        Utils.SafeAddItem(container, pending.meat)
                    end
                    Utils.LogInfo("  [CampScene] OnContainerUpdate: Added " ..
                        pending.count .. "x " .. pending.meat .. " to " .. bagType)

                    table.remove(pendingBags, i)
                    -- else
                    --     Utils.LogInfo("  [CampScene] Failed to get container from object")
                end
                -- else
                --     Utils.LogInfo("  [CampScene] Types don't match")
            end
        end
    end
end

-- Subscribe to game event
Events.OnContainerUpdate.Add(OnContainerUpdate)

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Gets spawn chance based on LootQuality setting
---@param settings table
---@return number chance (0-100)
local function getLootQualityChance(settings)
    local lootQuality = settings.lootQuality or 1

    if lootQuality == 1 then
        -- Dynamic: Based on world tier
        local tier = WorldTier.GetWorldTier()
        if tier == "EARLY" then return 50 end
        if tier == "MID" then return 75 end
        if tier == "LATE" then return 90 end
        return 100 -- END
    elseif lootQuality == 2 then
        return 50  -- Poor
    elseif lootQuality == 3 then
        return 75  -- Normal
    else
        return 90  -- Rich
    end
end

---Finds or creates a campfire on a square
---@param sq IsoGridSquare
---@return IsoFireplace|nil
local function createCampfire(sq)
    local cell = sq:getCell()
    local sprite = getSprite("camping_01_6")

    -- Create new IsoFireplace
    local campfire = IsoFireplace.new(cell, sq, sprite)
    return campfire
end

---Sets up campfire and optional loot (bag with meat, branches)
---@param sq IsoGridSquare
---@param settings table
local function setupCampfire(sq, settings)
    local campfire = createCampfire(sq)
    if not campfire then
        Utils.LogInfo("  [CampScene] Failed to create campfire")
        return
    end
    campfire:addToWorld()
    Utils.LogInfo("  [CampScene] Campfire added to world")

    -- Meat spawning: chance based on LootQuality
    local meatChance = getLootQualityChance(settings)
    if Utils.RollProbability(meatChance) then
        local bagType = CAMP_BAG_TYPES[ZombRand(#CAMP_BAG_TYPES) + 1]
        local bag = sq:AddWorldInventoryItem(bagType, 0, 0, 0)

        if bag then
            local meat = CAMPFIRE_MEAT_ITEMS[ZombRand(#CAMPFIRE_MEAT_ITEMS) + 1]
            local count = ZombRand(1, 4)

            -- Store pending bag data for OnContainerUpdate
            table.insert(pendingBags, {
                bag = bag,
                meat = meat,
                count = count
            })

            -- Trigger container update (InventoryContainer uses getInventory)
            if instanceof(bag, "InventoryContainer") then
                triggerEvent("OnContainerUpdate", bag)
            end

            Utils.LogInfo("  [CampScene] Spawned " .. bagType .. ", pending " .. count .. "x " .. meat)
            -- else
            --     Utils.LogInfo("  [CampScene] Failed to spawn bag")
        end
    end
end

---Spawns camp structures (tents, campfire)
---@param x number
---@param y number
---@param z number
---@param sceneType string "Single" or "Multi"
---@param settings table
---@return boolean success, number|nil sx, number|nil sy
local function spawnCampStructures(x, y, z, sceneType, settings)
    local cell = getCell()
    local spawnSq = nil

    -- Find valid 2x2 area for camp structures
    for _ = 1, 20 do
        local ox = ZombRand(-10, 11)
        local oy = ZombRand(-10, 11)
        local s = cell:getGridSquare(x + ox, y + oy, z)
        if s and RandomizedWorldBase.is2x2AreaClear(s) then
            spawnSq = s
            break
        end
    end

    if not spawnSq then
        Utils.LogInfo("  [CampScene] Failed to find clear 2x2 area for camp structures.")
        return false, nil, nil
    end

    local sx, sy = spawnSq:getX(), spawnSq:getY()
    Utils.LogInfo("  [CampScene] Found valid area at " .. sx .. "," .. sy)

    -- Spawn structures using RandomizedWorldBase
    local rwb = RandomizedWorldBase.new()

    -- Always spawn campfire
    rwb:addCampfire(spawnSq)

    -- Setup campfire (lighting + meat)
    setupCampfire(spawnSq, settings)

    -- Tent spawn chance based on LootQuality
    local tentChance = getLootQualityChance(settings)
    local tentOrientation = ZombRand(2)

    -- Tent 1 (random orientation)
    if Utils.RollProbability(tentChance) then
        if tentOrientation == 0 then
            rwb:addRandomTentNorthSouth(sx + 2, sy, z)
        else
            rwb:addRandomTentWestEast(sx, sy + 2, z)
        end
        Utils.LogInfo("  [CampScene] Added tent 1")
    else
        Utils.LogInfo("  [CampScene] Tent 1 skipped (chance: " .. tentChance .. "%)")
    end

    if sceneType == "Multi" then
        -- Tent 2 (opposite orientation from tent 1)
        if Utils.RollProbability(tentChance) then
            if tentOrientation == 0 then
                rwb:addRandomTentWestEast(sx, sy + 2, z)
            else
                rwb:addRandomTentNorthSouth(sx + 2, sy, z)
            end
            Utils.LogInfo("  [CampScene] Added tent 2")
        else
            Utils.LogInfo("  [CampScene] Tent 2 skipped (chance: " .. tentChance .. "%)")
        end
    end

    return true, sx, sy
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Generates a camp scene (wraps CombatScene + adds camp structures)
---@param x number
---@param y number
---@param z number
---@param settings table
---@param sceneType string "Single" or "Multi"
---@param eventType string "Gunfight", "Gunshot", or "Scream"
---@return boolean success, table|nil corpseDataList
function ReactiveSE_CampScene.Spawn(x, y, z, settings, sceneType, eventType)
    Utils.LogInfo("--------------------------------------------------")
    Utils.LogInfo("Spawning Camp Scene (" .. sceneType .. ", " .. eventType .. ") at " .. x .. "," .. y)

    -- 1. Spawn camp structures (tents, campfire)
    local structureSuccess, campX, campY = spawnCampStructures(x, y, z, sceneType, settings)

    -- Use camp center for corpse spawning if structures placed, otherwise original position
    local spawnX = campX or x
    local spawnY = campY or y

    -- 2. Build config based on event type (same logic as regular scenes)
    local config = {}

    if eventType == "Gunfight" then
        -- Multi-corpse, with firearms
        config.minCorpses = 2
        config.maxCorpses = settings.corpseCount or 4
    elseif eventType == "Gunshot" then
        -- Single corpse, with firearms, reduced loot
        config.minCorpses = 1
        config.maxCorpses = 1
        config.stealChanceMod = 0.5
    elseif eventType == "Scream" then
        -- Single corpse, no firearms, with zombies
        config.minCorpses = 1
        config.maxCorpses = 1
        config.noFirearms = true
        config.maxZombies = settings.screamZombieCount or 0
    end

    -- 3. Delegate to CombatScene for corpse/zombie generation (same as regular scenes)
    local success, corpseDataList = CombatScene.Spawn(spawnX, spawnY, z, settings, config)

    if not structureSuccess and not success then
        Utils.LogInfo("  [CampScene] Failed to create scene.")
        return false, nil
    end

    Utils.LogInfo("  [CampScene] Complete.")
    return true, corpseDataList
end

return ReactiveSE_CampScene
