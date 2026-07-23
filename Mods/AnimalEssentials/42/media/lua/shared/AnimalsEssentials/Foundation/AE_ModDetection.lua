AE_ModDetection = {}
AE_ModDetection.KNOWN_MODS = {
    ["AE_FrameworkCore"] = {
        required = false,
        detected = false,
        loadOrder = 2,
        detectionMethod = "global",
        detectionTarget = "AE_CommandsSystem",
        description = "AnimalsEssentials Framework Core - Commands and Behavior"
    },
    ["KittyMod"] = {
        required = false,
        detected = false,
        loadOrder = 3,
        detectionMethod = "global",
        detectionTarget = "KittyMod_Core",
        description = "KittyMod - Cat Management System"
    }
}

AE_ModDetection.detectionResults = {}
AE_ModDetection.lastDetectionTime = 0
AE_ModDetection.detectionComplete = false

function AE_ModDetection.detectMod(modName)
    local modConfig = AE_ModDetection.KNOWN_MODS[modName]
    if not modConfig then
        return false
    end
    
    local detected = false
    
    if modConfig.detectionMethod == "global" then
        detected = _G[modConfig.detectionTarget] ~= nil
    elseif modConfig.detectionMethod == "function" then
        detected = type(_G[modConfig.detectionTarget]) == "function"
    elseif modConfig.detectionMethod == "table" then
        local target = _G[modConfig.detectionTarget]
        detected = target ~= nil and type(target) == "table"
    end
    
    modConfig.detected = detected
    return detected
end

function AE_ModDetection.detectAllMods()
    AE_ModDetection.detectionResults = {}
    local detectedCount = 0
    
    for modName, modConfig in pairs(AE_ModDetection.KNOWN_MODS) do
        local detected = AE_ModDetection.detectMod(modName)
        AE_ModDetection.detectionResults[modName] = detected
        
        if detected then
            detectedCount = detectedCount + 1
            print("[AE_ModDetection] Detected mod: " .. modName .. " (" .. modConfig.description .. ")")
        end
    end
    
    AE_ModDetection.lastDetectionTime = GameTime.getServerTimeMills()
    AE_ModDetection.detectionComplete = true
    
    print("[AE_ModDetection] Detection complete: " .. detectedCount .. " mods detected")
    
    if AE_EventRegistry then
        AE_EventRegistry.safeFireEvent("OnAE_ModRegistration", {
            detectedMods = AE_ModDetection.detectionResults,
            detectedCount = detectedCount,
            timestamp = AE_ModDetection.lastDetectionTime
        })
    end
    
    return detectedCount
end

function AE_ModDetection.isModAvailable(modName)
    if AE_ModDetection.detectionResults[modName] ~= nil then
        return AE_ModDetection.detectionResults[modName]
    end
    
    return AE_ModDetection.detectMod(modName)
end

function AE_ModDetection.getAvailableMods()
    local available = {}
    for modName, detected in pairs(AE_ModDetection.detectionResults) do
        if detected then
            table.insert(available, modName)
        end
    end
    return available
end

function AE_ModDetection.getMissingMods()
    local missing = {}
    for modName, detected in pairs(AE_ModDetection.detectionResults) do
        if not detected then
            table.insert(missing, modName)
        end
    end
    return missing
end

function AE_ModDetection.registerMod(modName, config)
    if not modName or not config then
        print("[AE_ModDetection] ERROR: Invalid mod registration parameters")
        return false
    end
    
    AE_ModDetection.KNOWN_MODS[modName] = {
        required = config.required or false,
        detected = false,
        loadOrder = config.loadOrder or 999,
        detectionMethod = config.detectionMethod or "global",
        detectionTarget = config.detectionTarget or modName,
        description = config.description or modName
    }
    
    print("[AE_ModDetection] Registered mod for detection: " .. modName)
    return true
end

function AE_ModDetection.waitForMod(modName, timeoutMs, callback)
    timeoutMs = timeoutMs or 5000
    local startTime = GameTime.getServerTimeMills()
    
    local function checkMod()
        if AE_ModDetection.isModAvailable(modName) then
            if callback then callback(true) end
            return true
        elseif GameTime.getServerTimeMills() - startTime > timeoutMs then
            print("[AE_ModDetection] Timeout waiting for mod: " .. modName)
            if callback then callback(false) end
            return false
        else
            local function delayedModCheck()
                Events.OnTick.Remove(delayedModCheck)
                checkMod()
            end
            Events.OnTick.Add(delayedModCheck)
            return nil
        end
    end
    
    return checkMod()
end

function AE_ModDetection.getLoadOrder()
    local mods = {}
    for modName, config in pairs(AE_ModDetection.KNOWN_MODS) do
        if config.detected then
            table.insert(mods, {name = modName, order = config.loadOrder})
        end
    end
    
    table.sort(mods, function(a, b) return a.order < b.order end)
    
    local ordered = {}
    for _, mod in ipairs(mods) do
        table.insert(ordered, mod.name)
    end
    
    return ordered
end

function AE_ModDetection.initialize()
    print("[AE_ModDetection] Initializing mod detection system...")
    
    Events.OnGameStart.Add(function()
        local function delayedModDetection()
            Events.OnTick.Remove(delayedModDetection)
            AE_ModDetection.detectAllMods()
        end
        Events.OnTick.Add(delayedModDetection)
    end)
    
    print("[AE_ModDetection] Mod detection system initialized")
end

_G.AE_ModDetection = AE_ModDetection

return AE_ModDetection