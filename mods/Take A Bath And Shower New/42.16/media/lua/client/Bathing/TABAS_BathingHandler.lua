TABAS_BathingHandler = {}

TABAS_BathingHandler.BathingInstances = {}

local TABAS_BathingManager = require("Bathing/TABAS_BathingManager")
local TABAS_Utils = require("TABAS_Utils")

local function setModDataFlag(playerObj, key, value)
    local md = playerObj:getModData()
    if md and md[key] ~= value then
        md[key] = value
        playerObj:transmitModData()
    end
end

function TABAS_BathingHandler.isValid(playerObj, mode)
    if not playerObj or playerObj:isDead() then return false end
    return mode == "BATH" or mode == "SHOWER"
end

function TABAS_BathingHandler.getBathingManager(playerObj)
    if not playerObj then return nil end
    local playerKey = TABAS_Utils.getPlayerKey(playerObj)
    return TABAS_BathingHandler.BathingInstances[playerKey]
end

function TABAS_BathingHandler.getOrCreateBathingManager(playerObj)
    if not playerObj then return nil end

    local playerKey = TABAS_Utils.getPlayerKey(playerObj)
    local manager = TABAS_BathingHandler.BathingInstances[playerKey]
    if not manager then
        manager = TABAS_BathingManager:new(playerObj)
        TABAS_BathingHandler.BathingInstances[playerKey] = manager
    end
    return manager
end

function TABAS_BathingHandler.onBathingStart(playerObj, mode, session)
    if not TABAS_BathingHandler.isValid(playerObj, mode) then return nil end

    local manager = TABAS_BathingHandler.getOrCreateBathingManager(playerObj)
    if manager then
        manager:attachSession(mode, session)
    end
    setModDataFlag(playerObj, "tabas_IsBathing", true)
    return manager
end

function TABAS_BathingHandler.onBathingEnd(playerObj, completed)
    local manager = TABAS_BathingHandler.getBathingManager(playerObj)
    if manager then
        manager:detachSession(completed)
    end
    setModDataFlag(playerObj, "tabas_IsBathing", nil)
    return manager
end

function TABAS_BathingHandler.onBathingWetStart(playerObj)
    setModDataFlag(playerObj, "tabas_HasBathingWet", true)
end

function TABAS_BathingHandler.onBathingStateFinished(playerObj)
    if not playerObj then return end

    setModDataFlag(playerObj, "tabas_HasBathingWet", nil)

    local playerKey = TABAS_Utils.getPlayerKey(playerObj)
    local manager = TABAS_BathingHandler.BathingInstances[playerKey]
    if manager then
        manager:destroy()
        TABAS_BathingHandler.BathingInstances[playerKey] = nil
    end
end

function TABAS_BathingHandler.onGameStart()
    for i = 0, getNumActivePlayers() - 1 do
        local playerObj = getSpecificPlayer(i)
        if playerObj then
            TABAS_BathingHandler.onBathingStateFinished(playerObj)
        end
    end
end

LuaEventManager.AddEvent("OnBathingStart")
LuaEventManager.AddEvent("OnBathingEnd")
LuaEventManager.AddEvent("OnBathingWetStart")
LuaEventManager.AddEvent("OnBathingStateFinished")
Events.OnBathingStart.Add(TABAS_BathingHandler.onBathingStart)
Events.OnBathingEnd.Add(TABAS_BathingHandler.onBathingEnd)
Events.OnBathingWetStart.Add(TABAS_BathingHandler.onBathingWetStart)
Events.OnBathingStateFinished.Add(TABAS_BathingHandler.onBathingStateFinished)
Events.OnGameStart.Add(TABAS_BathingHandler.onGameStart)
Events.OnPlayerDeath.Add(TABAS_BathingHandler.onBathingStateFinished)

return TABAS_BathingHandler
