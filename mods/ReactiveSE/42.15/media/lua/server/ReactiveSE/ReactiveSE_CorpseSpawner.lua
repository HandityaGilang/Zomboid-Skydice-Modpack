--//////////////////////////////////////////////////--
--    Reactive Sound Events - Corpse Spawner
--    Handles the generation and spawning of individual corpses
--    with their associated kits and loot.
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local WorldTier = require "ReactiveSE/ReactiveSE_WorldTier"
local Outfits = require "ReactiveSE/ReactiveSE_Outfits"
local Archetypes = require "ReactiveSE/ReactiveSE_Archetypes"
local BaseKits = require "ReactiveSE/ReactiveSE_BaseKits"
local VirtualKit = require "ReactiveSE/ReactiveSE_VirtualKit"
local LootSimulation = require "ReactiveSE/ReactiveSE_LootSimulation"
local KitRealizer = require "ReactiveSE/ReactiveSE_KitRealizer"
local CorpseSanitizer = require "ReactiveSE/ReactiveSE_CorpseSanitizer"

local ReactiveSE_CorpseSpawner = {}

--//////////////////////////////////////////////////--
--          Helper Functions                       --
--//////////////////////////////////////////////////--

---Adds blood splatter to a grid square
---@param sq IsoGridSquare
---@param intensity number|nil 1=light, 2=medium, 3=heavy (default: medium)
function ReactiveSE_CorpseSpawner.SpawnGore(sq, intensity)
    if not sq then return end
    intensity = intensity or 2
    local samples
    if intensity == 1 then
        samples = ZombRand(1, 3)
    elseif intensity == 3 then
        samples = ZombRand(4, 8)
    else
        samples = ZombRand(2, 5)
    end
    for _ = 1, samples do
        sq:splatBlood(ZombRand(1, 10) / 2.0, ZombRand(3, 10))
    end
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Spawns a detailed corpse using the Survivor Kit System
---@param sq IsoGridSquare
---@param settings table
---@param sceneType string (Optional, for context/archetype selection if needed later)
---@param overrides table|nil (Optional: { worldTier=string, category=string, subTier=string })
---@return table|nil corpseData { x, y, z } or nil if spawn failed
function ReactiveSE_CorpseSpawner.Spawn(sq, settings, sceneType, overrides)
    if not sq then return nil end

    local worldTier = (overrides and overrides.worldTier) or WorldTier.GetWorldTier()

    Utils.LogInfo("  [CorpseSpawner] Processing new corpse. WorldTier: " .. tostring(worldTier))

    -- 1. Determine gender and Outfit
    local isFemale = ZombRand(2) == 0
    local catFilter = overrides and overrides.category
    local subFilter = overrides and overrides.subTier
    local outfit, category, subTier = Outfits.SelectOutfit(worldTier, isFemale, catFilter, subFilter)

    -- 2. Spawn Dead Body directly (Engine native)
    local femaleChanceInt = isFemale and 100 or 0
    local crawlerChance = 0
    local bloodLevel = 10
    local dir = IsoDirections.getRandom()

    local deadBody = RandomizedWorldBase.createRandomDeadBody(
        sq,
        dir,
        true, -- alignToSquare
        bloodLevel,
        crawlerChance,
        outfit,
        femaleChanceInt
    )

    if deadBody then
        Utils.LogInfo("  [CorpseSpawner] Created DeadBody")
        Utils.LogInfo("  [CorpseSpawner] Attributes")
        Utils.LogInfo("    > Outfit: " .. tostring(outfit))
        Utils.LogInfo("    > Category: " .. tostring(category))
        Utils.LogInfo("    > SubTier: " .. tostring(subTier))
        Utils.LogInfo("    > Female: " .. tostring(isFemale))

        -- 4. Survivor Kit Generation (Virtual)
        local archetypeKey = category
        local archRules = Archetypes.GetRules(archetypeKey)
        local baseKit = BaseKits.SelectKit(archetypeKey, subTier, worldTier)

        Utils.LogInfo("  [CorpseSpawner] Generating Virtual Kit:")
        Utils.LogInfo("    > Archetype: " .. tostring(archetypeKey) .. " (" .. tostring(subTier) .. ")")
        Utils.LogInfo("    > BaseKit: " .. tostring(baseKit.name))

        -- 4a. Generate Data
        local vKit = VirtualKit.GenerateBase(baseKit, settings, archetypeKey)
        Utils.LogInfo("    > Base Items: Primary=" ..
            tostring(vKit.primaryWeapon) ..
            ", Sidearm=" .. tostring(vKit.sidearm) .. ", Backpack=" .. tostring(vKit.backpack))

        -- 4b. Generate SubKits
        local allowedSubKits = archRules.allowedSubKits
        if vKit.sidearm then
            allowedSubKits = {}
            for i = 1, #archRules.allowedSubKits do
                if archRules.allowedSubKits[i] ~= "MeleeWeapon" then
                    table.insert(allowedSubKits, archRules.allowedSubKits[i])
                end
            end
        end

        vKit.subKitItems = VirtualKit.GenerateSubKits(
            allowedSubKits,
            archRules.subKitChances,
            vKit.unlockedSubKits,
            worldTier,
            settings.lootQuality
        )
        Utils.LogInfo("    > SubKit Items generated: " .. #vKit.subKitItems)

        -- 4c. Simulate Looting
        LootSimulation.Simulate(vKit, settings)

        -- 4d. Sanitize Default Corpse Loot
        CorpseSanitizer.Sanitize(deadBody)

        -- 4e. Realize (Spawn) into Dead Body
        KitRealizer.Realize(deadBody, vKit, settings)

        Utils.LogInfo("  [CorpseSpawner] Corpse finalized.")
        return { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
    end
    return nil
end

return ReactiveSE_CorpseSpawner
