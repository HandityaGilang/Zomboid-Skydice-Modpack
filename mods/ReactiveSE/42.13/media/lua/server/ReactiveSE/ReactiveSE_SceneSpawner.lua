--//////////////////////////////////////////////////--
--    Reactive Sound Events - Scene Spawner
--    Coordinator for scene generation.
--    Delegates logic to specific scene modules.
--//////////////////////////////////////////////////--

if isClient() and not isServer() then return end

local Constants = require "ReactiveSE/ReactiveSE_Constants"
local Utils = require "ReactiveSE/ReactiveSE_Utils"
local Config = require "ReactiveSE/ReactiveSE_Config"
local GunfightScene = require "ReactiveSE/ReactiveSE_GunfightScene"
local VehicleScene = require "ReactiveSE/ReactiveSE_VehicleScene"
local GunshotScene = require "ReactiveSE/ReactiveSE_GunshotScene"
local ScreamScene = require "ReactiveSE/ReactiveSE_ScreamScene"
local ZombieScene = require "ReactiveSE/ReactiveSE_ZombieScene"
local CampScene = require "ReactiveSE/ReactiveSE_CampScene"

local ReactiveSE_SceneSpawner = {}

-- Scene Module Registry (Command Pattern)
local SCENE_MODULES = {
    [Constants.EventTypes.GUNFIGHT]      = GunfightScene,
    [Constants.EventTypes.VEHICLE_CRASH] = VehicleScene,
    [Constants.EventTypes.GUNSHOT]       = GunshotScene,
    [Constants.EventTypes.SCREAM]        = ScreamScene,
    [Constants.EventTypes.ZOMBIE]        = ZombieScene
}

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Checks if a specific event type has a registered scene module
---@param eventType string
---@return boolean
function ReactiveSE_SceneSpawner.Supports(eventType)
    return SCENE_MODULES[eventType] ~= nil
end

---Main entry point for scene generation
---@param sceneData table { type=string, x=number, y=number, z=number }
---@return boolean success, string|nil failureReason
function ReactiveSE_SceneSpawner.Spawn(sceneData)
    local xVal = sceneData.x
    local yVal = sceneData.y
    local zVal = sceneData.z or 0

    -- Get current configuration flags
    local config = Config.Get()
    local scenes = config.scenes or Constants.Defaults
    local scenesTypes = config.sceneTypes or {}

    -- Ensure chunk is loaded
    local sq = getCell():getGridSquare(xVal, yVal, zVal)
    if not sq then
        Utils.LogInfo("[SceneSpawner] Chunk not loaded at " .. xVal .. "," .. yVal .. "," .. zVal)
        return false, "CHUNK_UNLOADED"
    end

    Utils.LogInfo("--------------------------------------------------")
    Utils.LogInfo("Requesting Scene Spawn Type: " .. tostring(sceneData.type))
    Utils.LogInfo("  > Location: " .. xVal .. "," .. yVal .. "," .. zVal)

    -- Check if scene type is enabled via per-event scene toggles
    local sceneConfigKey = Constants.SceneConfigMap[sceneData.type]
    if sceneConfigKey and scenesTypes[sceneConfigKey] == false then
        Utils.LogInfo("[SceneSpawner] Scene type " .. tostring(sceneData.type) .. " is disabled in config")
        return false, "DISABLED"
    end

    -- Zone Check: Determine if spawn location is in wilderness
    local zoneType = sq:getZoneType()
    local isUrban = Constants.UrbanZones[zoneType] or false

    -- BLOCK: VehicleCrash outside urban zones (roads, towns)
    if sceneData.type == Constants.EventTypes.VEHICLE_CRASH and not isUrban then
        Utils.LogInfo("Blocked VehicleCrash scene: spawn location is not urban (" .. tostring(zoneType) .. ")")
        return false, "BLOCKED"
    end

    -- Non-urban zones get Camp Scenes for Gunfight/Gunshot/Scream
    if not isUrban then
        -- Gunfight -> Multi-person Camp
        if sceneData.type == Constants.EventTypes.GUNFIGHT then
            local success, corpseDataList = CampScene.Spawn(xVal, yVal, zVal, scenes, "Multi", "Gunfight")
            if success and corpseDataList then
                sceneData.corpseDataList = corpseDataList
            end
            return success
        end

        -- Gunshot -> Single-person Camp
        if sceneData.type == Constants.EventTypes.GUNSHOT then
            local success, corpseDataList = CampScene.Spawn(xVal, yVal, zVal, scenes, "Single", "Gunshot")
            if success and corpseDataList then
                sceneData.corpseDataList = corpseDataList
            end
            return success
        end

        -- Scream -> Single-person Camp
        if sceneData.type == Constants.EventTypes.SCREAM then
            local success, corpseDataList = CampScene.Spawn(xVal, yVal, zVal, scenes, "Single", "Scream")
            if success and corpseDataList then
                sceneData.corpseDataList = corpseDataList
            end
            return success
        end
    end

    local module = SCENE_MODULES[sceneData.type]
    if module and module.Spawn then
        if sceneData.type == Constants.EventTypes.ZOMBIE then
            local success, specialZombieData = module.Spawn(xVal, yVal, zVal, scenes)
            if success and specialZombieData then
                sceneData.specialZombieData = specialZombieData
            end
            return success
        else
            local success, corpseDataList = module.Spawn(xVal, yVal, zVal, scenes)
            if success and corpseDataList and #corpseDataList > 0 then
                sceneData.corpseDataList = corpseDataList
            end
            return success
        end
    end

    Utils.LogWarning("Unknown or ignored scene type: " .. tostring(sceneData.type))
    return false
end

return ReactiveSE_SceneSpawner
