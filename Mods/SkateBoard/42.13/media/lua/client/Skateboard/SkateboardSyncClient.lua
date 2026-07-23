require("Skateboard/SkateboardCore")
require("Skateboard/SkateboardOptions")

if not isClient() then
    return
end

local Core = Skateboard.Core
local Options = Skateboard.Options

local Handlers = {}
Handlers[Core.SyncModule] = {}
local lastRemoteSoundUpdate = 0
local remoteSoundUpdateMs = 250

---@param player IsoPlayer
---@param baseVolume number
---@param soundRange number
---@return number|nil
local function getRemoteVolume(player, baseVolume, soundRange)
    local localPlayer = getPlayer() or getSpecificPlayer(0)
    if localPlayer and soundRange > 0 then
        local distance = Core.getDistance2D(
            player:getX(),
            player:getY(),
            localPlayer:getX(),
            localPlayer:getY()
        )
        if distance > soundRange then
            return nil
        end

        local t = math.min(distance / soundRange, 1.0)
        return baseVolume * (1.0 - t) * (1.0 - t)
    end

    return baseVolume
end

---@param player IsoPlayer
---@return nil
local function stopSkateboardAudio(player)
    local emitter = player:getEmitter()
    if not emitter then
        return
    end
    local modData = player:getModData()
    modData.skateboardSoundIds = modData.skateboardSoundIds or {}

    if emitter:isPlaying("SkateboardRolling") then
        emitter:stopSoundByName("SkateboardRolling")
    end
    if emitter:isPlaying("SkateboardToHand") then
        emitter:stopSoundByName("SkateboardToHand")
    end
    if emitter:isPlaying("SkateboardOllie") then
        emitter:stopSoundByName("SkateboardOllie")
    end

    modData.skateboardRollingVolumeSet = false
    modData.skateboardSoundIds = {}
end

---@param soundName string
---@param baseVolume number
---@return number
local function getSoundBaseVolume(soundName, baseVolume)
    if soundName == "SkateboardToHand" then
        return baseVolume * 0.8
    end

    return baseVolume
end

---@param player IsoPlayer
---@param args table
---@return nil
local function syncRemoteSkateboardSound(player, args)
    if player.isLocalPlayer and player:isLocalPlayer() then
        return
    end

    local emitter = player:getEmitter()
    if not emitter then
        return
    end
    local modData = player:getModData()
    modData.skateboardSoundIds = modData.skateboardSoundIds or {}

    local soundName = args and args.sound or nil
    if not soundName then
        return
    end

    if not args.playing then
        if emitter:isPlaying(soundName) then
            emitter:stopSoundByName(soundName)
        end
        modData.skateboardSoundIds[soundName] = nil
        return
    end

    local soundVolume = 0.40
    local soundRange = 15
    local options = Options.get()
    if options then
        soundVolume = options:getOption(Options.Key.SoundVolume):getValue()
        soundRange = options:getOption(Options.Key.SoundRange):getValue()
    end

    local baseVolume = getSoundBaseVolume(soundName, soundVolume)
    local volume = getRemoteVolume(player, baseVolume, soundRange)
    if not volume then
        if emitter:isPlaying(soundName) then
            emitter:stopSoundByName(soundName)
        end
        modData.skateboardSoundIds[soundName] = nil
        return
    end

    if emitter:isPlaying(soundName) then
        emitter:stopSoundByName(soundName)
    end

    local sound = emitter:playSoundImpl(soundName, nil)
    emitter:setVolume(sound, volume)
    modData.skateboardSoundIds[soundName] = sound
end

---@param player IsoPlayer|nil
---@return nil
local function updateRemoteRollingSounds(player)
    if not (player and player.isLocalPlayer and player:isLocalPlayer()) then
        return
    end

    local now = getTimestampMs()
    if now - lastRemoteSoundUpdate < remoteSoundUpdateMs then
        return
    end
    lastRemoteSoundUpdate = now

    local soundVolume = 0.40
    local soundRange = 15
    local options = Options.get()
    if options then
        soundVolume = options:getOption(Options.Key.SoundVolume):getValue()
        soundRange = options:getOption(Options.Key.SoundRange):getValue()
    end
    local baseVolume = getSoundBaseVolume("SkateboardRolling", soundVolume)

    local function syncRollingForPlayer(remote)
        if not remote or (remote.isLocalPlayer and remote:isLocalPlayer()) then
            return
        end

        local emitter = remote:getEmitter()
        if not emitter then
            return
        end

        local modData = remote:getModData()
        modData.skateboardSoundIds = modData.skateboardSoundIds or {}

        local isMoving = remote.getVariableBoolean and remote:getVariableBoolean("ismoving") or false
        if remote.isPlayerMoving then
            isMoving = remote:isPlayerMoving()
        end

        local shouldPlay = remote:getVariableBoolean(Core.PlayerVars.Active)
            and remote:getVariableBoolean(Core.PlayerVars.Rolling)
            and isMoving

        if not shouldPlay then
            if emitter:isPlaying("SkateboardRolling") then
                emitter:stopSoundByName("SkateboardRolling")
            end
            modData.skateboardSoundIds["SkateboardRolling"] = nil
            return
        end

        local volume = getRemoteVolume(remote, baseVolume, soundRange)
        if not volume then
            if emitter:isPlaying("SkateboardRolling") then
                emitter:stopSoundByName("SkateboardRolling")
            end
            modData.skateboardSoundIds["SkateboardRolling"] = nil
            return
        end

        local soundId = modData.skateboardSoundIds["SkateboardRolling"]
        if soundId and emitter:isPlaying("SkateboardRolling") then
            emitter:setVolume(soundId, volume)
            return
        end

        if emitter:isPlaying("SkateboardRolling") then
            emitter:stopSoundByName("SkateboardRolling")
        end

        local sound = emitter:playSoundImpl("SkateboardRolling", nil)
        emitter:setVolume(sound, volume)
        modData.skateboardSoundIds["SkateboardRolling"] = sound
    end

    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for index = 0, onlinePlayers:size() - 1 do
            syncRollingForPlayer(onlinePlayers:get(index))
        end
        return
    end

    local playerCount = getNumActivePlayers and getNumActivePlayers() or 1
    for playerIndex = 0, playerCount - 1 do
        syncRollingForPlayer(getSpecificPlayer(playerIndex))
    end
end

---@param args table
---@return nil
Handlers[Core.SyncModule].SetActive = function(args)
    local remote = getPlayerByOnlineID(args.id)
    if not remote then
        return
    end

    remote:setVariable(Core.PlayerVars.Active, tostring(args.active and "true" or "false"))
end

---@param args table
---@return nil
Handlers[Core.SyncModule].SetState = function(args)
    local remote = getPlayerByOnlineID(args.id)
    if not remote then
        return
    end

    remote:setVariable(Core.PlayerVars.Active, tostring(args.active and "true" or "false"))
    remote:setVariable(Core.PlayerVars.Held, tostring(args.held and "true" or "false"))
    remote:setVariable(Core.PlayerVars.Rolling, tostring(args.rolling and "true" or "false"))
    remote:setVariable(Core.PlayerVars.ToHandPlayed, tostring(args.toHandPlayed and "true" or "false"))
    remote:setVariable(Core.PlayerVars.WalkSpeed, args.walkSpeed or 1.0)
    remote:setVariable(Core.PlayerVars.RunSpeed, args.runSpeed or 1.0)
    remote:setVariable(Core.PlayerVars.Speed, args.speed or 1.0)
    remote:setVariable(Core.PlayerVars.Ollie, tostring(args.ollie and "true" or "false"))
    remote:setVariable(Core.PlayerVars.OllieStarted, tostring(args.ollieStarted and "true" or "false"))

    if not args.active then
        remote:setVariable(Core.PlayerVars.RollingTimestamp, "0")
        remote:setVariable(Core.PlayerVars.ToHandPlayed, "false")
        stopSkateboardAudio(remote)
    end
end

---@param args table
---@return nil
Handlers[Core.SyncModule].Sound = function(args)
    local remote = getPlayerByOnlineID(args.id)
    if not remote then
        return
    end

    syncRemoteSkateboardSound(remote, args)
end

---@param module string
---@param command string
---@param args table
---@return nil
local function handleServerCommand(module, command, args)
    local modTable = Handlers[module]
    if modTable and modTable[command] then
        modTable[command](args)
    end
end

---@return nil
local function requestRemoteSkateboardStates()
    sendClientCommand(Core.SyncModule, "RequestState", {})
end

Events.OnServerCommand.Add(handleServerCommand)
Events.OnPlayerUpdate.Add(updateRemoteRollingSounds)
Events.OnGameStart.Add(requestRemoteSkateboardStates)
