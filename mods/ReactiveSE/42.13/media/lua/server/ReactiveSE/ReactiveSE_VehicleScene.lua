--//////////////////////////////////////////////////--
--    Reactive Sound Events - Vehicle Scene
--    Handles generation of vehicle crash scenes
--//////////////////////////////////////////////////--

if isClient() and not isServer() then return end

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local CorpseSpawner = require "ReactiveSE/ReactiveSE_CorpseSpawner"

local ReactiveSE_VehicleScene = {}

--//////////////////////////////////////////////////--
--          Configuration                         --
--//////////////////////////////////////////////////--

-- Mapping of vehicle conditions (Enum 1-5) -> % Max Condition
local VEHICLE_CONDITION_MAP = {
    [1] = 20, -- Very Bad
    [2] = 35, -- Bad (Default)
    [3] = 50, -- Medium
    [4] = 65, -- Good
    [5] = 80  -- Pristine
}

-- Driver archetypes (50/50)
local DRIVER_CATEGORIES = { "SURVIVOR", "BANDIT" }

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Gets a random valid vehicle script
---@return string
local function getRandomVehicleScript()
    local scriptManager = getScriptManager()
    local scripts = scriptManager:getAllVehicleScripts()
    if not scripts or scripts:isEmpty() then return "Base.CarNormal" end

    local candidates = {}
    for i = 0, scripts:size() - 1 do
        local script = scripts:get(i) --[[@as VehicleScript]]
        local name = script:getName()
        local fullName = script:getFullName()
        -- Filter trailers, burnt, and smashed vehicles
        if not string.find(name, "Trailer") and not string.find(name, "Burnt") and not string.find(name, "Smashed") then
            table.insert(candidates, fullName)
        end
    end

    Utils.LogInfo("  [VehiclePool] Valid candidates: " .. #candidates)
    if #candidates == 0 then return "Base.VanCarpenter" end
    return candidates[ZombRand(#candidates) + 1]
end

---Fills trunk with procedural loot using game's distribution system
---@param vehicle BaseVehicle
local function populateTrunk(vehicle)
    local trunk = vehicle:getTrunkPart()
    if not trunk then return end

    local container = trunk:getItemContainer()
    if not container then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    ItemPickerJava.fillContainer(container, nil) -- nil is allowed here
end

---Fills glove box with procedural loot
---@param vehicle BaseVehicle
local function populateGloveBox(vehicle)
    local gloveBox = vehicle:getPartById("GloveBox")
    if not gloveBox then return end

    local container = gloveBox:getItemContainer()
    if not container then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    ItemPickerJava.fillContainer(container, nil) -- nil is allowed here
end

---Spawns driver corpse next to vehicle
---@param x number
---@param y number
---@param z number
---@param settings table
---@param category string
---@return table|nil corpseData
local function spawnDriver(x, y, z, settings, category)
    -- Find spot next to vehicle
    for attempt = 1, 10 do
        local ox = ZombRand(-2, 3)
        local oy = ZombRand(-2, 3)
        local oxAbs = Utils.Abs(ox)
        local oyAbs = Utils.Abs(oy)
        if oxAbs + oyAbs > 0 then
            local cell = getCell()
            local sq = cell:getGridSquare(x + ox, y + oy, z)
            if sq and sq:isFree(false) then
                local overrides = { category = category }
                local corpseData = CorpseSpawner.Spawn(sq, settings, "VehicleCrash", overrides)
                CorpseSpawner.SpawnGore(sq, 2)
                return corpseData
            end
        end
    end
    Utils.LogInfo("  > Failed to find spot for driver corpse")
    return nil
end

---Spawns zombie victim (the thing that was hit)
---@param x number
---@param y number
---@param z number
---@param settings table
---@return table|nil corpseData
local function spawnZombieVictim(x, y, z, settings)
    -- Spawn in front of vehicle (offset 2-3 tiles)
    for attempt = 1, 10 do
        local ox = ZombRand(-3, 4)
        local oy = ZombRand(-3, 4)
        local oxAbs = Utils.Abs(ox)
        local oyAbs = Utils.Abs(oy)
        if oxAbs + oyAbs >= 2 then
            local cell = getCell()
            local sq = cell:getGridSquare(x + ox, y + oy, z)
            if sq and sq:isFree(false) then
                local overrides = { category = "CIVILIAN" }
                local corpseData = CorpseSpawner.Spawn(sq, settings, "VehicleCrash", overrides)
                CorpseSpawner.SpawnGore(sq, 2)
                Utils.LogInfo("  > Zombie victim at " .. (x + ox) .. "," .. (y + oy))
                return corpseData
            end
        end
    end
    Utils.LogInfo("  > Failed to find spot for zombie victim")
    return nil
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Generates a detailed vehicle crash scene
---@param x number
---@param y number
---@param z number
---@param settings table
---@return boolean success, table|nil corpseDataList
function ReactiveSE_VehicleScene.Spawn(x, y, z, settings)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return false, nil end

    -- Check no existing vehicle
    if sq:getVehicleContainer() ~= nil then return false, nil end
    local movingObjects = sq:getMovingObjects()
    if movingObjects then
        for i = 0, movingObjects:size() - 1 do
            if instanceof(movingObjects:get(i), "BaseVehicle") then
                return false, nil
            end
        end
    end

    Utils.LogInfo("--------------------------------------------------")
    Utils.LogInfo("Spawning Vehicle Crash Scene at " .. x .. "," .. y)

    -- 1. Select driver archetype (50/50 SURVIVOR or BANDIT)
    local driverCategory = DRIVER_CATEGORIES[ZombRand(1, 3)]

    -- 2. Spawn Vehicle
    local scriptName = getRandomVehicleScript()
    Utils.LogInfo("  > Vehicle: " .. tostring(scriptName))
    local vehicle = addVehicle(scriptName, sq:getX(), sq:getY(), sq:getZ())

    if not vehicle then
        Utils.LogWarning("  > Failed to spawn vehicle")
        return false, nil
    end
    Utils.LogInfo("  > Vehicle spawned. ID: " .. tostring(vehicle:getId()))

    -- 3. Apply damage
    local maxCond = VEHICLE_CONDITION_MAP[settings.vehicleMaxCondition] or 20
    local generalCondition = ZombRand(0, maxCond)
    vehicle:setGeneralPartCondition(0, generalCondition)
    vehicle:setRust(ZombRandFloat(0.3, 0.8))
    Utils.LogInfo("  > General condition: " .. generalCondition .. "% (max: " .. maxCond .. "%)")

    -- Windshield broken (crash damage)
    local windshield = vehicle:getPartById("Windshield")
    if windshield then
        windshield:setCondition(0)
        Utils.LogInfo("  > Windshield broken")
    end

    -- Front damage
    local criticalParts = {
        { id = "Engine",         damageRange = { 0.4, 1.0 } },
        { id = "FrontLeftDoor",  damageRange = { 0.4, 0.8 } },
        { id = "FrontRightDoor", damageRange = { 0.4, 0.8 } },
        { id = "Hood",           damageRange = { 0.2, 0.6 } },
    }

    for i = 1, 4 do
        local partInfo = criticalParts[i]
        local part = vehicle:getPartById(partInfo.id)
        if part then
            local damagePercent = ZombRandFloat(partInfo.damageRange[1], partInfo.damageRange[2])
            local newCondition = Utils.Floor(maxCond * (1.0 - damagePercent))
            part:setCondition(Utils.Max(0, newCondition))
            Utils.LogInfo("  > Damaged " .. partInfo.id .. " to " .. newCondition .. "%")
        end
    end

    -- 4. Gasoline (5-25% of tank capacity)
    local gasTank = vehicle:getPartById("GasTank")
    if gasTank then
        local capacity = gasTank:getContainerCapacity() or 50
        local fuelPercent = ZombRandFloat(0.05, 0.25)
        local fuelAmount = capacity * fuelPercent
        gasTank:setContainerContentAmount(fuelAmount)
        Utils.LogInfo("  > Fuel: " ..
            Utils.Floor(fuelAmount) .. "/" .. Utils.Floor(capacity) .. " (" .. Utils.Floor(fuelPercent * 100) .. "%)")
    end

    -- 5. Key system
    if ZombRand(100) < (settings.vehicleKeyChance or 25) then
        local gloveBox = vehicle:getPartById("GloveBox")
        if gloveBox and gloveBox:getItemContainer() then
            local key = Utils.SafeAddItem(gloveBox:getItemContainer(), "Base.CarKey")
            if key then
                key:setKeyId(vehicle:getKeyId())
                Utils.LogInfo("  > Key in glove box")
            end
        end
    else
        vehicle:setKeyId(-1)
        Utils.LogInfo("  > No key")
    end

    -- 6. Trunk and glove box loot (procedural)
    populateTrunk(vehicle)
    populateGloveBox(vehicle)

    -- 7. Spawn corpses and collect data for resurrection
    local corpseDataList = {}

    local driverData = spawnDriver(x, y, z, settings, driverCategory)
    if driverData then
        table.insert(corpseDataList, driverData)
    end

    local victimData = spawnZombieVictim(x, y, z, settings)
    if victimData then
        table.insert(corpseDataList, victimData)
    end

    Utils.LogInfo("Vehicle crash scene complete.")
    return true, corpseDataList
end

return ReactiveSE_VehicleScene
