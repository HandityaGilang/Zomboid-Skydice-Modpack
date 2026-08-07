local AE_EnvironmentDetector = {}

local environmentCache = {
    detected = false,
    isSinglePlayer = false,
    isMultiplayer = false,
    isServer = false,
    isClient = false,
    detectionTrigger = nil,
    detectionTime = 0
}

local function detectEnvironmentNow()
    if environmentCache.detected then
        return
    end

    local success, result = pcall(function() return isMultiplayer() end)
    if not success then
        environmentCache.isSinglePlayer = true
        environmentCache.isMultiplayer = false
    else
        environmentCache.isMultiplayer = result or false
        environmentCache.isSinglePlayer = not environmentCache.isMultiplayer
    end

    local serverSuccess, serverResult = pcall(function() return isServer() end)
    environmentCache.isServer = serverSuccess and serverResult or false

    local clientSuccess, clientResult = pcall(function() return isClient() end)
    environmentCache.isClient = clientSuccess and clientResult or false

    environmentCache.detected = true
    environmentCache.detectionTime = getTimestamp()

    if environmentCache.detectionTrigger == nil then
        environmentCache.detectionTrigger = "lazy"
    end
end

local function onPlayerMove(player)
    if environmentCache.detected and environmentCache.detectionTrigger == "onplayermove" then
        return
    end

    local success, result = pcall(function() return isMultiplayer() end)
    if not success then
        environmentCache.isSinglePlayer = true
        environmentCache.isMultiplayer = false
    else
        environmentCache.isMultiplayer = result or false
        environmentCache.isSinglePlayer = not environmentCache.isMultiplayer
    end

    local serverSuccess, serverResult = pcall(function() return isServer() end)
    environmentCache.isServer = serverSuccess and serverResult or false

    local clientSuccess, clientResult = pcall(function() return isClient() end)
    environmentCache.isClient = clientSuccess and clientResult or false

    environmentCache.detected = true
    environmentCache.detectionTrigger = "onplayermove"
    environmentCache.detectionTime = getTimestamp()

    print("[AE_EnvironmentDetector] Environment detected (OnPlayerMove): " ..
          (environmentCache.isSinglePlayer and "SP" or "MP") ..
          " | Server: " .. tostring(environmentCache.isServer) ..
          " | Client: " .. tostring(environmentCache.isClient))

    if Events and Events.AE_EnvironmentDetected then
        Events.AE_EnvironmentDetected.Trigger({
            isSinglePlayer = environmentCache.isSinglePlayer,
            isMultiplayer = environmentCache.isMultiplayer,
            isServer = environmentCache.isServer,
            isClient = environmentCache.isClient,
            detectionTrigger = "onplayermove",
            timestamp = environmentCache.detectionTime
        })
    end

    if Events and Events.OnPlayerMove then
        Events.OnPlayerMove.Remove(onPlayerMove)
    end
end

function AE_EnvironmentDetector.isMultiplayer()
    if not environmentCache.detected then
        detectEnvironmentNow()
    end
    return environmentCache.isMultiplayer
end

function AE_EnvironmentDetector.isSinglePlayer()
    if not environmentCache.detected then
        detectEnvironmentNow()
    end
    return environmentCache.isSinglePlayer
end

function AE_EnvironmentDetector.isServer()
    if not environmentCache.detected then
        detectEnvironmentNow()
    end
    return environmentCache.isServer
end

function AE_EnvironmentDetector.isClient()
    if not environmentCache.detected then
        detectEnvironmentNow()
    end
    return environmentCache.isClient
end

function AE_EnvironmentDetector.getEnvironmentInfo()
    if not environmentCache.detected then
        detectEnvironmentNow()
    end

    return {
        detected = environmentCache.detected,
        isSinglePlayer = environmentCache.isSinglePlayer,
        isMultiplayer = environmentCache.isMultiplayer,
        isServer = environmentCache.isServer,
        isClient = environmentCache.isClient,
        detectionTrigger = environmentCache.detectionTrigger,
        detectionTime = environmentCache.detectionTime
    }
end

return AE_EnvironmentDetector
