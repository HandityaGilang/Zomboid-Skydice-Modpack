--//////////////////////////////////////////////////--
--    Reactive Sound Events - Zombie Scene
--    Spawns a group of zombies at event location.
--    One special zombie has full survivor kit.
--//////////////////////////////////////////////////--

if isClient() and not isServer() then return end

local Constants = require "ReactiveSE/ReactiveSE_Constants"
local Utils = require "ReactiveSE/ReactiveSE_Utils"
local WorldTier = require "ReactiveSE/ReactiveSE_WorldTier"
local OutfitData = require "ReactiveSE/ReactiveSE_OutfitData"
local CorpseSpawner = require "ReactiveSE/ReactiveSE_CorpseSpawner"

local ReactiveSE_ZombieScene = {}

--//////////////////////////////////////////////////--
--          Outfit Configuration                  --
--//////////////////////////////////////////////////--

-- Special zombie outfit options (33% each)
local SPECIAL_ZOMBIE_TYPES = {
    {
        name = "SURVIVOR",
        outfits = { "Survivalist", "Survivalist02", "Survivalist03", "Survivalist04", "Survivalist05" },
        category = "SURVIVOR",
        buddyOutfits = "CIVILIAN_STANDARD"
    },
    {
        name = "BANDIT",
        outfits = { "Bandit_Mid" },
        category = "BANDIT",
        buddyOutfits = "CIVILIAN_STANDARD"
    },
    {
        name = "MILITARY",
        outfits = { "ArmyServiceUniform" },
        category = "MILITARY",
        buddyOutfits = "AUTHORITY_BASIC"
    }
}

---Selects special zombie type and outfit
---@return table { name, outfit, category, buddyOutfits }
local function selectSpecialZombieType()
    local typeIndex = ZombRand(1, 4) -- 1, 2, or 3 (33% each)
    local typeData = SPECIAL_ZOMBIE_TYPES[typeIndex]
    local outfit = typeData.outfits[ZombRand(1, #typeData.outfits + 1)]
    return {
        name = typeData.name,
        outfit = outfit,
        category = typeData.category,
        buddyOutfits = typeData.buddyOutfits
    }
end

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Spawns regular zombies at location with themed outfits
---@param x number
---@param y number
---@param z number
---@param count number
---@param radius number
---@param buddyOutfitType string "CIVILIAN_STANDARD" or "AUTHORITY_BASIC"
local function spawnRegularZombies(x, y, z, count, radius, buddyOutfitType)
    -- Parse the outfit type string (e.g., "CIVILIAN_STANDARD" -> "CIVILIAN", "STANDARD")
    local category, subcategory = buddyOutfitType:match("^(%w+)_(%w+)$")
    if not category then
        category = "CIVILIAN"
        subcategory = "STANDARD"
    end

    for i = 1, count do
        local ox = ZombRand(-radius, radius + 1)
        local oy = ZombRand(-radius, radius + 1)
        local targetX = x + ox
        local targetY = y + oy

        local sq = getCell():getGridSquare(targetX, targetY, z)
        if sq and sq:isFree(false) then
            local outfit = OutfitData.GetRandomOutfit(category, subcategory)
            addZombiesInOutfit(targetX, targetY, z, 1, outfit, 0)
            Utils.LogInfo("  > Spawned buddy zombie (" .. outfit .. ") at " .. targetX .. "," .. targetY)
        end
    end
end

---Spawns special loot zombie (as corpse, then reanimate)
---@param x number
---@param y number
---@param z number
---@param settings table
---@param specialType table
---@return table|nil specialZombieData
local function spawnSpecialZombie(x, y, z, settings, specialType)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return nil end

    -- Find a free spot near center
    local spawnSq = sq
    local spawnX, spawnY = x, y

    for attempt = 1, 10 do
        local ox = ZombRand(-2, 3)
        local oy = ZombRand(-2, 3)
        local testSq = getCell():getGridSquare(x + ox, y + oy, z)
        if testSq and testSq:isFree(false) then
            spawnSq = testSq
            spawnX = x + ox
            spawnY = y + oy
            break
        end
    end

    Utils.LogInfo("  > Spawning special zombie (" .. specialType.name .. ": " .. specialType.outfit .. ")")

    -- Spawn as corpse with full kit
    local overrides = {
        category = specialType.category,
        outfit = specialType.outfit,
        worldTier = WorldTier.GetWorldTier()
    }

    CorpseSpawner.Spawn(spawnSq, settings, "ZombieSpecial", overrides)

    -- Find the corpse we just spawned and reanimate it
    local deadBodies = spawnSq:getDeadBodys()
    if deadBodies and deadBodies:size() > 0 then
        local corpse = deadBodies:get(deadBodies:size() - 1) --[[@as IsoDeadBody]]
        if corpse then
            local currentTime = getGameTime():getWorldAgeHours()
            corpse:setReanimateTime(currentTime)
            Utils.LogInfo("  > Special zombie reanimated at " .. spawnX .. "," .. spawnY)
        end
    end

    return {
        x = spawnX,
        y = spawnY,
        z = z,
        type = specialType.name,
        spawnTime = getGameTime():getWorldAgeHours()
    }
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Generates a zombie scene with multiple zombies
---@param x number
---@param y number
---@param z number
---@param settings table
---@return boolean success, table|nil specialZombieData
function ReactiveSE_ZombieScene.Spawn(x, y, z, settings)
    Utils.LogInfo("--------------------------------------------------")
    Utils.LogInfo("Spawning Zombie Scene at " .. x .. "," .. y)

    -- Get zombie count from settings or defaults
    local minZombies = settings.zombieSceneMin or Constants.Defaults.ZOMBIE_SCENE_MIN or 3
    local maxZombies = settings.zombieSceneMax or Constants.Defaults.ZOMBIE_SCENE_MAX or 9
    local radius = Constants.Defaults.ZOMBIE_SCENE_RADIUS or 5

    local count = ZombRand(minZombies, maxZombies + 1)
    Utils.LogInfo("  > Spawning " .. count .. " zombies (range: " .. minZombies .. "-" .. maxZombies .. ")")

    -- Determine special zombie type (33% each: Survivor, Bandit, Military)
    local specialType = selectSpecialZombieType()
    Utils.LogInfo("  > Special zombie type: " .. specialType.name)

    -- Spawn regular zombies (count - 1, since 1 is special)
    local regularCount = count - 1
    if regularCount > 0 then
        spawnRegularZombies(x, y, z, regularCount, radius, specialType.buddyOutfits)
    end

    -- Spawn special loot zombie
    local specialData = spawnSpecialZombie(x, y, z, settings, specialType)

    Utils.LogInfo("Zombie scene generation complete.")

    return true, specialData
end

return ReactiveSE_ZombieScene
