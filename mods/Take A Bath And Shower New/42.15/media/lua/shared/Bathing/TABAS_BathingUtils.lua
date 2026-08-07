local TABAS_BathingUtils = {}

local TABAS_BathingDefs = require("Bathing/TABAS_BathingDefs")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_Sounds = require("TABAS_Sounds")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

local GAZE_CHECK_INTERVAL_MS = 300
local GAZE_ACTIVATE_SEC      = 1.5
local GAZE_DEACTIVATE_SEC    = 0.8
local BATHING_WET_DELAY_SEC  = 120
local BATHING_COMFORT_DELAY_SEC = 300
local BATHING_BATH_WET_MIN_TEMP = 30.0
local BATHING_BATH_LOW_WATER_WET_RATE = 0.35

function TABAS_BathingUtils.noise(title, text)
    TABAS_Utils.debugPrint(title, text)
end

function TABAS_BathingUtils.hasBathingElapsed(modData, delaySec)
    if not modData or not modData.tabas_IsBathing then return false end

    local startH = modData.tabas_BathingStartH
    if not startH then return false end

    local nowH = TABAS_GameTimes.getWorldAgeHours()
    local elapsedSec = (nowH - startH) * 3600
    local requiredSec = delaySec or 0
    return elapsedSec >= requiredSec
end

function TABAS_BathingUtils.getBathingWetDelaySec()
    return BATHING_WET_DELAY_SEC
end

function TABAS_BathingUtils.getBathingComfortDelaySec()
    return BATHING_COMFORT_DELAY_SEC
end

function TABAS_BathingUtils.getBathWetMinTemp()
    return BATHING_BATH_WET_MIN_TEMP
end

function TABAS_BathingUtils.getBathWaterState(tfc_Base)
    local state = {
        hasFluid = false,
        enoughWater = false,
        temperatureConcept = SandboxVars.TakeABathAndShower.WaterTemperatureConcept ~= false,
        waterTemp = 0,
        wetRate = 0,
        canWet = false,
        canComfort = false,
        canBenefit = false,
    }

    if not tfc_Base or not tfc_Base:hasFluid() then
        return state
    end

    state.hasFluid = true
    state.enoughWater = not tfc_Base:isLowWater()
    state.waterTemp = tfc_Base:getWaterTemperature()
    state.wetRate = state.enoughWater and 1.0 or BATHING_BATH_LOW_WATER_WET_RATE
    state.canWet = state.wetRate > 0

    if state.temperatureConcept then
        state.canComfort = state.enoughWater and tfc_Base:isHotWater()
        state.canBenefit = state.enoughWater and state.waterTemp >= BATHING_BATH_WET_MIN_TEMP
    else
        state.canBenefit = state.enoughWater
    end

    return state
end

function TABAS_BathingUtils.endBathing(character, isCompleted, clearAnim)
    if not character then return false end

    local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")
    local session = TABAS_TakeBathSession:get(character)
    if session and session.isFinished then
        return false
    end
    if session then
        if session.bathingWetTime > 0 then
            TABAS_BathingUtils.setBathingWetEndH(character, session.bathingWetTime, isCompleted, true, false)
        end
        if session.consumedWater > 0 then
            local sq = session.baseSq
            sendClientCommand("tabas_tfc", "removeFluid", { x= sq:getX(), y=sq:getY(), z=sq:getZ(), amount=session.consumedWater })
        end
        if not isCompleted and session.tfc_Base then
            if not session.tfc_Base:isLowWater() then
                TABAS_Sounds.playPlayerSound(character, "tabas_bath_wave03")
            end
        end
        session.isFinished = true
    end

    if clearAnim ~= false then
        TABAS_AnimVariables.clearVariables(character, "BATH")
    end

    TABAS_BathingUtils.stopBathingBenefit(character)
    TABAS_BathingUtils.clearBathingModData(character, true)
    TABAS_BathingUtils.setBathingSuppression(character, false)
    character:setHeadLookAroundDirection(0.0, 0.0)

    if not isServer() then
        local TABAS_BathRadialMenu = require("UI/TABAS_BathRadialMenu")
        TABAS_BathRadialMenu.close(character)
    end

    TABAS_TakeBathSession:ended(character)
    return true
end

function TABAS_BathingUtils.clearBathingModData(character, bTransmit)
    if not character then return end
    local md = character:getModData()
    if not md then return end
    md.tabas_IsBathing = nil
    md.tabas_BathingStartH = nil
    md.tabas_ShowerEnded = nil
    md.tabas_ShowerCompleted = nil
    md.tabas_FeelingGaze = nil
    md.tabas_Comforted = nil
    md.tabas_BathingBenefit = nil
    if bTransmit then
        character:transmitModData()
    end
end

function TABAS_BathingUtils.setBathingSuppression(character, toggle)
    if character:isSneaking() then
        character:setSneaking(false)
    end
    if character:isAutoWalk() then
        character:setAutoWalk(false)
    end
    if character:getIgnoreMovement() ~= toggle then
        character:setIgnoreMovement(toggle)
    end
    if character:isIgnoreContextKey() ~= toggle then
        character:setIgnoreContextKey(toggle)
    end
    if character:isIgnoringAimingInput() ~= toggle then
        character:setIgnoreAimingInput(toggle)
    end
    if character:isHeadLookAround() ~= toggle then
        character:setHeadLookAround(toggle)
    end
end

--------------------- Take Bath Allowed Actions ---------------------

function TABAS_BathingUtils.isAllowedAction(action)
    if not action then return true end
    local name = action.Type or tostring(action)
    return TABAS_BathingDefs.ActionWhitelist[name] == true
end

function TABAS_BathingUtils.isAllowedCursor(drag)
    if not drag then return true end
    local name = drag.Type or tostring(drag)
    return TABAS_BathingDefs.CursorWhitelist[name] == true
end

function TABAS_BathingUtils.isDebugAllowedAllAction()
    return TABAS_Utils.DEBUG_ALLOWED_ALL_ACTION
end

function TABAS_BathingUtils.isTakingBath(character)
    -- if not character:getIgnoreMovement() then return false end
    if not character:getVariableBoolean("TABAS_TakeBath") or not character:getVariableBoolean("TABAS_BathStarted") then
        return false
    end
    return true
end

--------------------- Bathing Benefit ---------------------
--/ isClient / isServer /

function TABAS_BathingUtils.startBathingBenefit(player, mode, x, y, z)
    if isClient() then
        sendClientCommand("tabas_bathing", "startBathingBenefit", {mode = mode, x=x, y=y, z=z})
        return
    end
    local md = player:getModData()
    md.tabas_BathingBenefit = { mode = mode, x=x, y=y, z=z, startId = getTimestampMs() }
    player:transmitModData()
end

function TABAS_BathingUtils.stopBathingBenefit(player)
    if isClient() then
        sendClientCommand("tabas_bathing", "stopBathingBenefit", {})
        return
    end
    local md = player:getModData()
    md.tabas_BathingBenefit = nil
    player:transmitModData()
end

--------------------- Bathing Comforted ---------------------
-- / isClient/
local function evalState(worldTemp, isHotWater)
    if isHotWater then
        if worldTemp <= 30 then return "WARMING" end
        return nil
    else
        if worldTemp <= 10 then return "DISCOMFY" end
        if worldTemp >= 30 then return "COOLING" end
        return nil
    end
end

function TABAS_BathingUtils.newComfortState(playerNum)
    local confirmMF = TABAS_Compat.confirmMF
    return {
        moodleCooling = confirmMF("CoolingBody", playerNum),
        moodleWarming = confirmMF("WarmingBody", playerNum),
        coolingApplied = false,
        warmingApplied = false,
        lastState = nil
    }
end

function TABAS_BathingUtils.newGazeState(playerNum)
    local confirmMF = TABAS_Compat.confirmMF
    return {
        nextCheckMs = 0,
        lastMs = 0,
        seenAcc = 0.0,
        unseenAcc = 0.0,
        active = false,
        lastValue = 0.5,
        moodle = confirmMF("FeelingGaze", playerNum)
    }
end

-- state: nil | "DISCOMFY" | "COOLING" | "WARMING"
function TABAS_BathingUtils.updateComfortState(character, comfort, worldTemp, isHotWater)
    local state = evalState(worldTemp, isHotWater)
    if state == "DISCOMFY" then
        local stats = character and character:getStats()
        if stats and stats:get(CharacterStat.WETNESS) < 75 then
            TABAS_Utils.increaseCharacterWetness(character, 80)
        end
    end

    local comfortState = character:getModData().tabas_Comforted
    local nowComfort = (state == "COOLING") or (state == "WARMING")
    if (not comfortState) or comfortState ~= nowComfort then
        character:getModData().tabas_Comforted = nowComfort
        character:transmitModData()
    end

    if comfort then
        local cooling = comfort.moodleCooling
        local warming = comfort.moodleWarming

        if state == "COOLING" then
            if cooling and not comfort.coolingApplied then
                cooling:setValue(1)
                comfort.coolingApplied = true
            end
            if comfort.warmingApplied then
                comfort.warmingApplied = false
                if warming then warming:setValue(0.5) end
            end
        elseif state == "WARMING" then
            if warming and not comfort.warmingApplied then
                warming:setValue(1)
                comfort.warmingApplied = true
            end
            if comfort.coolingApplied then
                comfort.coolingApplied = false
                if cooling then cooling:setValue(0.5) end
            end
        else
            if comfort.coolingApplied then
                comfort.coolingApplied = false
                if cooling then cooling:setValue(0.5) end
            end
            if comfort.warmingApplied then
                comfort.warmingApplied = false
                if warming then warming:setValue(0.5) end
            end
        end

        comfort.lastState = state
    end

    return comfort, state
end

function TABAS_BathingUtils.clearComfortState(character, comfort)
    local md = character and character:getModData()
    if md and md.tabas_Comforted ~= false then
        md.tabas_Comforted = false
        character:transmitModData()
    end

    if comfort then
        comfort.coolingApplied = false
        comfort.warmingApplied = false
        comfort.lastState = nil

        local cooling = comfort.moodleCooling
        local warming = comfort.moodleWarming
        if cooling and cooling:getValue() ~= 0.5 then cooling:setValue(0.5) end
        if warming and warming:getValue() ~= 0.5 then warming:setValue(0.5) end
    end

    return comfort
end

--------------------- Feeling Gaze ---------------------

local function isBeingWatched(character, range, ignoreZed, ignoreUsers)
    if not character then return false, 0 end

    local r = range or 6
    local r2 = r * r
    local z0 = character:getZ()

    local seen = 0

    -- ---- Players ----
    local players = getOnlinePlayers()
    if players then
        for i=0, players:size()-1 do
            local p = players:get(i)
            if p ~= character and p:getZ() == z0 and not p:isAnimal() then

                if ignoreUsers then
                    local userName = p:getUsername() or nil
                    if userName and ignoreUsers[userName] then
                    else
                        local dx = p:getX() - character:getX()
                        local dy = p:getY() - character:getY()
                        if (dx*dx + dy*dy) <= r2 and p:CanSee(character) then
                            seen = seen + 1
                            if seen >= 4 then return true, seen end
                        end
                    end
                else
                    local dx = p:getX() - character:getX()
                    local dy = p:getY() - character:getY()
                    if (dx*dx + dy*dy) <= r2 and p:CanSee(character) then
                        seen = seen + 1
                        if seen >= 4 then return true, seen end
                    end
                end

            end
        end
    end

    -- ---- Zombies ----
    if not ignoreZed then
        local zombies = getCell() and getCell():getZombieList()
        if zombies then
            for i=0, zombies:size()-1 do
                local z = zombies:get(i)
                if z and z:getZ() == z0 then
                    local dx = z:getX() - character:getX()
                    local dy = z:getY() - character:getY()
                    if (dx*dx + dy*dy) <= r2 and z:CanSee(character) then
                        seen = seen + 1
                        if seen >= 4 then return true, seen end
                    end
                end
            end
        end
    end

    if seen > 0 then return true, seen end
    return false, 0
end

local function buildIgnoreUserSet(csv)
    local set = {}
    if not csv then return set end
    csv = tostring(csv)

    for token in csv:gmatch("([^,]+)") do
        token = token:gsub("^%s+", ""):gsub("%s+$", "")
        if token ~= "" then
            set[token] = true
        end
    end
    return set
end

-- / isClient/
function TABAS_BathingUtils.feelingGaze(character, gaze, nowMs, ignoreZed)
    if SandboxVars.TakeABathAndShower.DisableFeelingStressByGaze then return gaze, false end

    local dt = (nowMs - (gaze.lastMs or nowMs)) / 1000.0
    gaze.lastMs = nowMs
    if nowMs < (gaze.nextCheckMs or 0) then
        return gaze, false
    end
    gaze.nextCheckMs = nowMs + GAZE_CHECK_INTERVAL_MS

    local ignoreUsers = gaze._ignoreUsers
    if not ignoreUsers then
        local csv = TABAS_Utils.ModOptionsValue("DontMindWatchedBy") or ""
        gaze._ignoreUsers = buildIgnoreUserSet(csv)
        ignoreUsers = gaze._ignoreUsers
    end

    local watched, count = isBeingWatched(character, 8, ignoreZed, ignoreUsers)

    if watched then
        gaze.seenAcc = math.min(gaze.seenAcc + dt, 10.0)
        gaze.unseenAcc = 0.0
    else
        gaze.unseenAcc = math.min(gaze.unseenAcc + dt, 10.0)
        gaze.seenAcc = 0.0
    end

    if (not gaze.active) and gaze.seenAcc >= GAZE_ACTIVATE_SEC then
        gaze.active = true
    elseif gaze.active and gaze.unseenAcc >= GAZE_DEACTIVATE_SEC then
        gaze.active = false
    end

    local value = 0.5
    if gaze.active then
        if count == 1 then value = 0.4
        elseif count == 2 then value = 0.3
        elseif count == 3 then value = 0.2
        elseif count >= 4 then value = 0.1 end
    end

    if gaze.lastValue ~= value then
        gaze.lastValue = value
        if gaze.moodle and gaze.moodle.setValue then
            gaze.moodle:setValue(value)
        end
        character:getModData().tabas_FeelingGaze = math.max(count, 4)
        character:transmitModData()
    end
    return gaze
end

--------------------- Bathing Wet ---------------------

function TABAS_BathingUtils.setBathingWetEndH(character, wetSec, completed, bEndGrace, bTransmit)
    local md = character:getModData()
    local nowH = TABAS_GameTimes.getWorldAgeHours()

    if wetSec and wetSec > 0 then
        md.tabas_WetEndH = nowH + (wetSec / 3600)

        if bEndGrace then
            local graceSec = completed and 180 or 30
            md.tabas_WetGraceEndH = nowH + (graceSec / 3600)
        else
            md.tabas_WetGraceEndH = nil
        end

    else
        md.tabas_WetEndH = nil
    end

    if bTransmit then character:transmitModData() end
end

--------------------- Cleaning Body ---------------------

local MakeUpLocations = {
    ItemBodyLocation.MAKE_UP_FULL_FACE,
    ItemBodyLocation.MAKE_UP_EYES,
    ItemBodyLocation.MAKE_UP_EYES_SHADOW,
    ItemBodyLocation.MAKE_UP_LIPS
}

function TABAS_BathingUtils.hasMakeUp(character)
    for i=1, #MakeUpLocations do
        local makeup = character:getWornItem(MakeUpLocations[i])
        if makeup then
            return true
        end
    end
    return false
end

function TABAS_BathingUtils.removeAllMakeup(character)
    local inv = character:getInventory()
    local removed = 0
    for i=1, #MakeUpLocations do
        local makeup = character:getWornItem(MakeUpLocations[i])
        if makeup then
            character:removeWornItem(makeup)
            inv:Remove(makeup)
            removed = removed + 1
        end
    end
    return removed
end

function TABAS_BathingUtils.cleaningBody(character, pct, factor)
    local visual = character:getHumanVisual()
    local mul = pct * factor

    local bloodTotal, dirtTotal, decTotal = 0, 0, 0
    local maxIndex = BloodBodyPartType.MAX:index()

    for i=1, maxIndex do
        local part = BloodBodyPartType.FromIndex(i-1)
        local blood = visual:getBlood(part)
        if blood > 0 then
            local decrease = blood * mul
            local value = blood - decrease
            if value < 0 then decrease = blood; value = 0 end
            visual:setBlood(part, value)
            bloodTotal = bloodTotal + decrease
            decTotal = decTotal + decrease
        end

        local dirt = visual:getDirt(part)
        if dirt > 0 then
            local decrease = dirt * mul
            local value = dirt - decrease
            if value < 0 then decrease = dirt; value = 0 end
            visual:setDirt(part, value)
            dirtTotal = dirtTotal + decrease
            decTotal = decTotal + decrease
        end
    end
    TABAS_Utils.debugPrint("CleaningBody", "decreased: blood >> ".. tostring(bloodTotal) .. ", dirt >> " .. tostring(dirtTotal))
    character:resetModelNextFrame()
    syncVisuals(character)
    return decTotal
end

function TABAS_BathingUtils.cleaningGrime(character, pct, factor)
    local md = character:getModData()
    local grime = md.tabas_BodyGrime or 0
    if grime <= 0 then return 0 end

    local decrease = grime * (pct * factor)
    local value = grime - decrease
    if value < 0 then decrease = grime; value = 0 end

    md.tabas_BodyGrime = round(value, 2)
    character:transmitModData()
    TABAS_Utils.debugPrint("CleaningGrime", "decreased: grime >> ".. tostring(decrease))
    return decrease
end

function TABAS_BathingUtils.cleaningWornItems(character, wornItems, pct, factor)
    local mul = pct * factor
    local decTotal = 0
    local size = wornItems:size()

    for i=0, size-1 do
        local item = wornItems:get(i):getItem()
        if not item:isHidden() then
            local changed = false
            if item:IsClothing() then
                local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
                if coveredParts then
                    local psize = coveredParts:size()
                    for j=0, psize - 1 do
                        local part = coveredParts:get(j)
                        local value = item:getBlood(part)
                        if value > 0 then
                            local decrease = value * mul
                            item:setBlood(part, (value - decrease))
                            decTotal = decTotal + decrease
                            changed = true
                        end
                        value = item:getDirt(part)
                        if value > 0 then
                            local decrease = value * mul
                            item:setDirt(part, (value - decrease))
                            decTotal = decTotal + decrease
                            changed = true
                        end
                    end
                end
                if item:getWetness() < 100 then
                    item:setWetness(100)
                    changed = true
                end
                local dirty = item:getDirtiness()
                if dirty > 0 then
                    local decrease = dirty * mul
                    item:setDirtiness(dirty - decrease)
                    decTotal = decTotal + decrease * 0.01
                    changed = true
                end
            end
            local blood = item:getBloodLevel()
            if blood > 0 then
                local decrease = blood * mul
                item:setBloodLevel(blood - decrease)
                decTotal = decTotal + decrease * 0.01
                changed = true
            end
            if changed then
                syncItemFields(character, item)
            end
        end
    end

    syncVisuals(character)
    return decTotal
end

function TABAS_BathingUtils.washCleansedBody(character, wornItems, pct, grimeWashFactor, makeOff)
    if isClient() then
        local args = { pct = pct, factor = grimeWashFactor, makeOff = makeOff }
        sendClientCommand("tabas_bathing", "washCleansedBody", args)
        return
    end

    local cleansed = 0.3 -- This value is used to tainted tub water after the character leaves the bath. It is added each time the character washes off blood and dirt.

    cleansed = cleansed + TABAS_BathingUtils.cleaningBody(character, pct, 1)
    cleansed = cleansed + (TABAS_BathingUtils.cleaningGrime(character, pct, grimeWashFactor) * 0.3)

    local wornItemCount = TABAS_Utils.getWornClothesCountExcluded(wornItems, true)
    if wornItemCount > 0 then
        cleansed = cleansed + TABAS_BathingUtils.cleaningWornItems(character, wornItems, pct, 1)
    end
    if makeOff then
        cleansed = cleansed + TABAS_BathingUtils.removeAllMakeup(character)
    end
    triggerEvent("OnClothingUpdated", character)

    -- Transfer the cleansed stains into the bath water.
    if SandboxVars.TakeABathAndShower.TubWaterGetDirty then
        local sq = character:getCurrentSquare()
        local x, y, z = sq:getX(), sq:getY(), sq:getZ()
        local bathObj = TABAS_Iso.getBathObjectAt(x, y, z)
        if not bathObj then return end

        local tfc_Base = TFC_Utils.getTfcBaseOnServer(x, y, z, bathObj)
        if tfc_Base then
            local toDirt = cleansed
            tfc_Base:waterToDirt(toDirt)
            TABAS_Utils.debugPrint("waterToDirt", " +".. tostring(toDirt))
        end
    end
end

function TABAS_BathingUtils.wetWornItems(character, wornItems)
    if isClient() then
        sendClientCommand("tabas_bathing", "wetWornItems", {})
        return
    end
    local count = 0
    local increase = 25
    for i=0, wornItems:size()-1 do
        local item = wornItems:get(i):getItem()
        if item and item:IsClothing() and not item:isHidden() then
            local wet = item:getWetness()
            if wet and wet < 100 then
                item:setWetness(math.min(100, wet + increase))
                syncItemFields(character, item)
                count = count + 1
            end
        end
    end
    triggerEvent("OnClothingUpdated", character)
    return count == 0
end

return TABAS_BathingUtils
