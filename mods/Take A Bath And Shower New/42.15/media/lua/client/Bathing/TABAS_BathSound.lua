local TABAS_Sounds = require("TABAS_Sounds")

local BathSounds = {}

local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

BathSounds.ClimbSound = {
    enter = "tabas_bath_enter",
    enterlow = "tabas_bath_enter_low",
    exit = "tabas_bath_exit",
    exitlow = "tabas_bath_smallsplush01",
}

BathSounds.WalkSound = {
    low = "tabas_walkintub01",
    half = "tabas_walkintub02",
    filled = "tabas_bath_wave01",
}

local function getWaterLevelKeyAtSquare(sq)
    local data = TFC_Utils.getTFCRegisteredData(sq)
    if not data then return end

    local amount = data.amount
    local capacity = data.capacity
    local level = TFC_Utils.getWaterLevelKeyByRatio(amount / capacity)
    return level
end

local function isEmptyLevel(level)
    return level == nil or level == "empty"
end

local function playExitSound(player, level)
    if isEmptyLevel(level) then return end
    if level == "low" then
        TABAS_Sounds.playPlayerSound(player, BathSounds.ClimbSound.exitlow)
    else
        TABAS_Sounds.playPlayerSound(player, BathSounds.ClimbSound.exit)
    end
end

local function playEnterSound(player, level)
    if isEmptyLevel(level) then return end
    if level == "low" then
        TABAS_Sounds.playPlayerSound(player, BathSounds.ClimbSound.enterlow)
    else
        TABAS_Sounds.playPlayerSound(player, BathSounds.ClimbSound.enter)
    end
end

local function playWalkSound(player, level)
    if isEmptyLevel(level) then return end
    if level == "low" then
        TABAS_Sounds.playPlayerSound(player, BathSounds.WalkSound.low)
    elseif level == "halfLow" then
        TABAS_Sounds.playPlayerSound(player, BathSounds.WalkSound.half)
    else
        TABAS_Sounds.playPlayerSound(player, BathSounds.WalkSound.filled)
    end
end

local function getEnterDelayMs(level)
    if level == "empty" or level == nil then
        return nil
    end
    if level == "low" then
        return 480
    elseif level == "halfLow" then
        return 430
    elseif level == "half" then
        return 370
    else -- full
        return 350
    end
end

local function getWalkSoundInterval(level)
    if level == "low" then
        return 480
    elseif level == "halfLow" then
        return 680
    else
        return 1380
    end
end

-- ------------------------- Climb Splash Sound -------------------------

local ClimbSoundManager = {
    prevStarted = false,
    cache = nil, -- { mode, level, startMs, didEnterSound }
}

local function climbBathSound(player, nowMs)
    local started = player:getVariableBoolean("ClimbFenceStarted")

    if not started then
        ClimbSoundManager.prevStarted = false
        ClimbSoundManager.cache = nil
        return
    end

    if started and not ClimbSoundManager.prevStarted then
        local curSq = player:getCurrentSquare()
        if not curSq then
            ClimbSoundManager.prevStarted = started
            return
        end

        local dir = player:getDir()
        local toSq = curSq:getAdjacentSquare(dir)

        local mode = (toSq and TFC_Utils.hasTfcData(toSq)) and "enter" or "exit"
        local srcSq = (mode == "enter") and toSq or curSq
        local level = srcSq and getWaterLevelKeyAtSquare(srcSq) or nil

        ClimbSoundManager.cache = {
            mode = mode,
            level = level,
            startMs = nowMs,
            didEnterSound = false,
        }

        if mode == "exit" then
            playExitSound(player, level)
        end
    end

    ClimbSoundManager.prevStarted = started

    local cache = ClimbSoundManager.cache
    if cache and cache.mode == "enter" and not cache.didEnterSound then
        local delay = getEnterDelayMs(cache.level)
        if not delay then
            ClimbSoundManager.cache = nil
            return
        end
        if nowMs - cache.startMs >= delay then
            cache.didEnterSound = true
            playEnterSound(player, cache.level)
            ClimbSoundManager.cache = nil
        end
    end
end

-- ------------------------- Walk Splash Sound -------------------------

local WalkSoundManager = {
    lastSq = nil,
    inBath = false,
    level = nil,
    nextMs = 0,
}

local function walkInBathSound(player, nowMs)
    local sq = player:getCurrentSquare()
    if not sq then return end

    if WalkSoundManager.lastSq ~= sq then
        WalkSoundManager.lastSq = sq

        if TFC_Utils.hasTfcData(sq) then
            WalkSoundManager.inBath = true
            WalkSoundManager.level = getWaterLevelKeyAtSquare(sq)
        else
            WalkSoundManager.inBath = false
            WalkSoundManager.level = nil
        end
    end

    if not WalkSoundManager.inBath then return end
    if not player:isWalking() or nowMs < (WalkSoundManager.nextMs or 0) then return end

    local level = WalkSoundManager.level
    if level and level ~= "empty" then
        local interval = getWalkSoundInterval(level)
        WalkSoundManager.nextMs = nowMs + interval
        playWalkSound(player, level)
    end
end

function TABAS_Sounds.onPlayerUpdate(player)
    if not player or not player:isLocalPlayer() or player:isDead() then return end

    local nowMs = getTimestampMs()
    walkInBathSound(player, nowMs)
    climbBathSound(player, nowMs)
    -- takeBathSound(player)
end

Events.OnPlayerUpdate.Add(TABAS_Sounds.onPlayerUpdate)
