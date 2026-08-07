--//////////////////////////////////////////////////--
--    Reactive Sound Events - Scene Manager
--    Manages persistent post-event scenes
--//////////////////////////////////////////////////--

if isClient() and not isServer() then return end

local Constants               = require "ReactiveSE/ReactiveSE_Constants"
local Utils                   = require "ReactiveSE/ReactiveSE_Utils"
local Config                  = require "ReactiveSE/ReactiveSE_Config"
local SceneSpawner            = require "ReactiveSE/ReactiveSE_SceneSpawner"
local ResurrectionManager     = require "ReactiveSE/ReactiveSE_ResurrectionManager"

local ReactiveSE_SceneManager = {}

--//////////////////////////////////////////////////--
--          Internal Helpers                       --
--//////////////////////////////////////////////////--

---Checks if a scene has expired
---@param scene table
---@return boolean
local function isExpired(scene)
    local config = Config.Get()
    local hoursSince = 24

    if config.scenes then
        hoursSince = config.scenes.cleanupHours
    end

    if hoursSince == 0 then return false end

    local worldAge = Utils.GetWorldAge()
    return (worldAge - scene.timestamp) > hoursSince
end

---Notifies a player that a scene has spawned nearby
---@param player IsoPlayer
---@param scene table
local function notifyPlayer(player, scene)
    local config = Config.Get()
    if not config.scenes or not config.scenes.notify or not config.scenes.notify.enabled then
        return
    end

    local sceneType = scene.type

    -- Text notification: player says something
    if config.scenes.notify.text then
        local textKey = "IGUI_RSE_SceneNotify_" .. sceneType
        local text = getText(textKey)
        if text and text ~= textKey then
            player:Say(text)
        end
    end

    -- Marker notification: fire event for client-side handler
    if config.scenes.notify.marker then
        triggerEvent("OnSceneSpawned", {
            x = scene.x,
            y = scene.y,
            type = sceneType
        })
    end
end

---Notifies a player that a scene was not found/cleared
---@param player IsoPlayer
local function notifySceneClear(player)
    local config = Config.Get()
    if not config.scenes or not config.scenes.notify or not config.scenes.notify.enabled then
        return
    end

    local typeKey = "IGUI_RSE_SceneNotify_Clear"
    local typeText = getText(typeKey)

    if typeText and typeText ~= typeKey then
        player:Say(typeText)
    else
        -- Fallback if translation missing
        player:Say("I arrived too late. The scene is clear")
    end
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Initializes the manager (hooked to OnGameStart)
function ReactiveSE_SceneManager.Initialize()
    if not ReactiveSE_Initialize.IsSceneEnvEnabled() then
        Utils.LogInfo("SceneManager: Dedicated Server detected. Scene System disabled.")
        return
    end

    Events.EveryOneMinute.Add(ReactiveSE_SceneManager.OnOneMinute)

    if Events.OnReactiveSoundEvent then
        Events.OnReactiveSoundEvent.Add(ReactiveSE_SceneManager.RegisterEvent)
    end

    if Events.OnKnoxRelayIntelMarked then
        Events.OnKnoxRelayIntelMarked.Add(function(sceneId)
            ReactiveSE_SceneManager.MarkAsMarked(sceneId)
        end)
    end
end

---Registers a new pending scene from an event
---@param eventData table
function ReactiveSE_SceneManager.RegisterEvent(eventData)
    local config = Config.Get()

    -- Config checks
    if not config.scenes or not config.scenes.enabled then
        Utils.LogInfo("Scene generation skipped (disabled)")
        return
    end

    -- Filter enabled event types
    if not SceneSpawner.Supports(eventData.eventType) then
        Utils.LogInfo("Scene generation skipped (no scene module for type: " .. tostring(eventData.eventType) .. ")")
        return
    end

    -- Chance check
    if ZombRand(100) >= config.scenes.chance then
        Utils.LogInfo("Scene generation skipped (dice roll)")
        return
    end

    -- Create scene entry
    local scene = {
        id = tostring(os.time()) .. "_" .. tostring(ZombRand(1000)),
        x = eventData.x,
        y = eventData.y,
        z = 0,                          -- Default to ground level
        type = eventData.eventType,
        timestamp = eventData.worldAge, -- Use WorldAge hours
        generated = false
    }

    -- Access Central ModData
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData.scenes then modData.scenes = {} end

    -- Scene Cap (Performance Protection)
    local MAX_SCENES = 30
    if #modData.scenes >= MAX_SCENES then
        table.remove(modData.scenes, 1) -- Remove oldest
        Utils.LogInfo("SceneManager: Scene limit reached. Removed oldest scene.")
    end

    table.insert(modData.scenes, scene)

    Utils.LogInfo("Registered new pending scene: " .. scene.type .. " at " .. scene.x .. "," .. scene.y)
end

---Main update loop (Every minute)
function ReactiveSE_SceneManager.OnOneMinute()
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData.scenes or #modData.scenes == 0 then return end

    local players = Utils.GetAllPlayers()
    if not players or #players == 0 then
        return nil
    end

    -- Iterate in reverse to safely remove elements
    for i = #modData.scenes, 1, -1 do
        local scene = modData.scenes[i]
        local remove = false
        local expired = isExpired(scene)

        if not scene.generated then
            -- Scene not yet generated - check if player is close enough
            for j = 1, #players do
                local player = players[j]
                local dist = Utils.GetDistance(player:getX(), player:getY(), scene.x, scene.y)
                local sceneDist = Constants.Defaults.SCENE_ACTIVATION_DISTANCE

                if dist < sceneDist then
                    if expired then
                        notifySceneClear(player)
                        remove = true
                        Utils.LogInfo("Expired scene cleared upon arrival: " .. scene.id)
                    else
                        local success, failureReason = SceneSpawner.Spawn(scene)
                        if success then
                            scene.generated = true

                            -- Apply resurrection filter to corpseDataList
                            if scene.corpseDataList and #scene.corpseDataList > 0 then
                                local isScream = scene.type == Constants.EventTypes.SCREAM
                                scene.corpseDataList = ResurrectionManager.FilterForResurrection(
                                    scene.corpseDataList, isScream
                                )
                                -- If no corpses selected for resurrection, mark for removal
                                if #scene.corpseDataList == 0 then
                                    remove = true
                                end
                            else
                                remove = true
                            end

                            notifyPlayer(player, scene)
                            Utils.LogInfo("Scene generated successfully: " .. scene.id)
                        else
                            -- Handle failure
                            if failureReason == "CHUNK_UNLOADED" then
                                Utils.LogInfo("Scene spawn delayed: Chunk not loaded at " .. scene.x .. "," .. scene.y)
                            else
                                -- Hard failure (Blocked, Disabled, etc) -> Remove
                                if scene.type == Constants.EventTypes.VEHICLE_CRASH then
                                    Utils.LogInfo("VehicleCrash scene removed (non-urban spawn blocked): " .. scene.id)
                                else
                                    Utils.LogInfo("Scene spawn failed (" ..
                                        tostring(failureReason) .. "), removed: " .. scene.id)
                                end

                                notifySceneClear(player)
                                remove = true
                            end
                        end
                    end
                    break
                end
            end
        elseif expired then
            -- Scene already generated but now expired
            remove = true
            Utils.LogInfo("Generated scene expired and removed: " .. scene.id)
        elseif scene.corpseDataList and #scene.corpseDataList > 0 then
            scene.corpseDataList = ResurrectionManager.Process(scene.corpseDataList, players)
            if #scene.corpseDataList == 0 then
                remove = true
                Utils.LogInfo("Scene completed (all corpses processed): " .. scene.id)
            end
        else
            remove = true
        end

        if remove then
            table.remove(modData.scenes, i)
        end
    end
end

--//////////////////////////////////////////////////--
--          Radio Integration                      --
--//////////////////////////////////////////////////--

---Gets a random unspawned scene for radio broadcast
---@return table|nil scene
function ReactiveSE_SceneManager.GetUnspawnedScene()
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData.scenes then return nil end

    local candidates = {}
    local count = #modData.scenes
    for i = 1, count do
        local scene = modData.scenes[i]
        if not scene.generated then
            if not scene.radioBroadcasted or (scene.radioBroadcasted and not scene.radioMarked) then
                candidates[#candidates + 1] = scene
            end
        end
    end

    if #candidates == 0 then return nil end
    return candidates[ZombRand(#candidates) + 1]
end

---Marks a scene as broadcasted
---@param sceneId string
function ReactiveSE_SceneManager.MarkAsBroadcasted(sceneId)
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData.scenes then return end

    local count = #modData.scenes
    for i = 1, count do
        if modData.scenes[i].id == sceneId then
            modData.scenes[i].radioBroadcasted = true
            Utils.LogInfo("SceneManager: Marked scene as broadcasted: " .. sceneId)
            break
        end
    end
end

---Marks a scene as marked (player recorded the intel)
---@param sceneId string
function ReactiveSE_SceneManager.MarkAsMarked(sceneId)
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData.scenes then return end

    local count = #modData.scenes
    for i = 1, count do
        if modData.scenes[i].id == sceneId then
            modData.scenes[i].radioMarked = true
            Utils.LogInfo("SceneManager: Marked scene as marked by player: " .. sceneId)
            break
        end
    end
end

---Gets count of unspawned scenes available for broadcast
---@return number
function ReactiveSE_SceneManager.GetUnspawnedCount()
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData.scenes then return 0 end

    local count = 0
    local total = #modData.scenes
    for i = 1, total do
        local scene = modData.scenes[i]
        if not scene.generated then
            if not scene.radioBroadcasted or (scene.radioBroadcasted and not scene.radioMarked) then
                count = count + 1
            end
        end
    end
    return count
end

return ReactiveSE_SceneManager
