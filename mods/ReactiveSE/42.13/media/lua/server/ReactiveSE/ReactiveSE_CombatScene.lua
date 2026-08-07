--//////////////////////////////////////////////////--
--    Reactive Sound Events - Combat Scene
--    Shared logic for firearm/combat scenes
--    Handles generation of corpses, gore, and evidence
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local CorpseSpawner = require "ReactiveSE/ReactiveSE_CorpseSpawner"
local OutfitData = require "ReactiveSE/ReactiveSE_OutfitData"

local ReactiveSE_CombatScene = {}

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Adds an item to the world square
---@param sq IsoGridSquare
---@param itemType string
local function spawnItem(sq, itemType)
    if not sq or not itemType then return end
    sq:AddWorldInventoryItem(itemType, 0, 0, 0)
end

---Spawns regular zombies around the scene
---@param x number Center X
---@param y number Center Y
---@param z number Z level
---@param count number Number of zombies to spawn
---@param radius number Spawn radius
local function spawnZombies(x, y, z, count, radius)
    for i = 1, count do
        local ox = ZombRand(-radius, radius + 1)
        local oy = ZombRand(-radius, radius + 1)
        local targetX = x + ox
        local targetY = y + oy

        local cell = getCell()
        local sq = cell:getGridSquare(targetX, targetY, z)
        if sq and sq:isFree(false) then
            local outfit = OutfitData.GetRandomOutfit("CIVILIAN", "STANDARD")
            addZombiesInOutfit(targetX, targetY, z, 1, outfit, 0)
            Utils.LogInfo("    > Spawned zombie (" .. outfit .. ") at " .. targetX .. "," .. targetY)
        end
    end
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Generates a combat scene with corpses and evidence
---@param x number
---@param y number
---@param z number
---@param settings table
---@param config table|nil Configuration overrides { minCorpses=int, maxCorpses=int, stealChanceMod=float, noFirearms=bool, maxZombies=int }
---@return boolean success, table|nil corpseDataList
function ReactiveSE_CombatScene.Spawn(x, y, z, settings, config)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return false, nil end
    if not sq:isSafeToSpawn() then return false, nil end

    config = config or {}
    local minCorpses = config.minCorpses or 1
    local maxCorpses = config.maxCorpses or 1
    local stealChanceMod = config.stealChanceMod
    local noFirearms = config.noFirearms or false
    local maxZombies = config.maxZombies or 0

    -- Clone settings if we need to modify them
    local sceneSettings = settings
    if stealChanceMod or noFirearms then
        sceneSettings = Utils.ShallowCopy(settings)
        if stealChanceMod then
            sceneSettings.stealChanceMod = stealChanceMod
        end
        if noFirearms then
            sceneSettings.noFirearms = true
        end
    end

    Utils.LogInfo("Spawning Combat Scene at " .. x .. "," .. y ..
        " (Corpses: " .. minCorpses .. "-" .. maxCorpses .. ")")

    -- 1. Determine Corpse Count
    local count = ZombRand(minCorpses, maxCorpses + 1)
    local corpseDataList = {}

    local bulletTypes = {
        "Base.223Bullets",
        "Base.308Bullets",
        "Base.Bullets38",
        "Base.Bullets44",
        "Base.Bullets9mm",
        "Base.556Bullets",
        "Base.ShotgunShells"
    }

    -- 2. Spawn Corpses
    local radius = maxCorpses == 1 and 1 or 3
    for i = 1, count do
        local tsq, actualX, actualY = Utils.FindSpawnSquare(x, y, z, radius, 3)

        if tsq then
            Utils.LogInfo("    > Spawning corpse " .. i .. " at " .. actualX .. "," .. actualY)

            local bulletType = bulletTypes[ZombRand(#bulletTypes) + 1]

            local corpseData = CorpseSpawner.Spawn(tsq, sceneSettings, "Combat")
            if corpseData then
                table.insert(corpseDataList, corpseData)
            end
            CorpseSpawner.SpawnGore(tsq, 2)

            -- Ballistic evidence (scattered)
            local cx = actualX + ZombRand(-1, 2)
            local cy = actualY + ZombRand(-1, 2)
            local csq = getCell():getGridSquare(cx, cy, z)
            if csq then
                spawnItem(csq, bulletType)
            end
        else
            Utils.LogInfo("    > Failed to find spot for corpse " .. i .. " after 3 attempts.")
        end
    end

    Utils.LogInfo("Combat scene generation complete. " .. #corpseDataList .. "/" .. count .. " corpses spawned.")

    -- Fallback: If we aimed for at least 1 but got 0, force one at center
    if count > 0 and #corpseDataList == 0 then
        Utils.LogInfo("    > No valid spots found. Spawning 1 corpse at center (fallback).")
        local corpseData = CorpseSpawner.Spawn(sq, sceneSettings, "Combat")
        if corpseData then
            table.insert(corpseDataList, corpseData)
        end
        CorpseSpawner.SpawnGore(sq, 2)
    end

    -- 3. Spawn Zombies (optional, 0 to maxZombies)
    if maxZombies > 0 then
        local zombieCount = ZombRand(0, maxZombies + 1)
        if zombieCount > 0 then
            Utils.LogInfo("    > Spawning " .. zombieCount .. " zombies (max: " .. maxZombies .. ")")
            spawnZombies(x, y, z, zombieCount, radius + 2)
        else
            Utils.LogInfo("    > No zombies spawned (rolled 0 out of max " .. maxZombies .. ")")
        end
    end

    return true, corpseDataList
end

return ReactiveSE_CombatScene
