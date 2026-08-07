local TABAS_BathingUtils = {}

local TABAS_BathingDefs = require("Bathing/TABAS_BathingDefs")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_BodyGrimeUtils = require("TABAS_BodyGrimeUtils")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_Sounds = require("TABAS_Sounds")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

local BATHING_BATH_WET_MIN_TEMP = 30.0
local BATHING_BATH_LOW_WATER_WET_RATE = 0.35
local BATHING_HOT_WATER_THRESHOLD = 45.0

function TABAS_BathingUtils.noise(title, text)
    TABAS_Utils.debugPrint(title, text)
end

function TABAS_BathingUtils.defaultBathWaterState()
    return  {
        hasFluid = false,
        enoughWater = false,
        temperatureConcept = SandboxVars.TakeABathAndShower.WaterTemperatureConcept ~= false,
        waterTemp = 0,
        wetRate = 0,
        canWet = false,
        canComfort = false,
        canBenefit = false,
    }
end

function TABAS_BathingUtils.getHotWaterThreshold()
    return BATHING_HOT_WATER_THRESHOLD
end

function TABAS_BathingUtils.isWaterTooHot(tfc_Base, threshold)
    threshold = threshold or TABAS_BathingUtils.getHotWaterThreshold()
    if not tfc_Base or not tfc_Base:hasFluid() then return false end
    local waterTemp = tfc_Base:getWaterTemperature()
    return waterTemp ~= nil and waterTemp > threshold
end

function TABAS_BathingUtils.sayTooHot(character)
    if character then
        character:Say(getText("IGUI_TABAS_ThatsTooHot"))
    end
end

function TABAS_BathingUtils.getBathWaterState(tfc_Base)
    local state = TABAS_BathingUtils.defaultBathWaterState()
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
    if isServer() then return end
    if not character then return false end

    local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")
    local session = TABAS_TakeBathSession:get(character)
    if session and session.isFinished then
        return false
    end
    if session then
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

    TABAS_BathingUtils.setBathingSuppression(character, false)
    character:setHeadLookAroundDirection(0.0, 0.0)

    local TABAS_BathRadialMenu = require("UI/TABAS_BathRadialMenu")
    TABAS_BathRadialMenu.close(character)

    TABAS_TakeBathSession:ended(character)
    triggerEvent("OnBathingEnd", character)
    return true
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
    local TABAS_BathingBenefitHandler = require("Bathing/TABAS_BathingBenefitHandler")
    TABAS_BathingBenefitHandler.start(player, mode, x, y, z)
end

function TABAS_BathingUtils.stopBathingBenefit(player)
    if isClient() then
        sendClientCommand("tabas_bathing", "stopBathingBenefit", {})
        return
    end
    local TABAS_BathingBenefitHandler = require("Bathing/TABAS_BathingBenefitHandler")
    TABAS_BathingBenefitHandler.stop(player)
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
    return decTotal
end

function TABAS_BathingUtils.cleaningGrime(character, pct, factor)
    local md = character:getModData()
    local grime = md.tabas_BodyGrime or 0
    if grime <= 0 then return 0 end

    local decrease = grime * (pct * factor)
    local value = grime - decrease
    if value < 0 then decrease = grime; value = 0 end

    TABAS_BodyGrimeUtils.setBodyGrime(character, value)
    TABAS_Utils.debugPrint("CleaningGrime", "decreased: grime >> ".. tostring(decrease))
    return decrease
end

function TABAS_BathingUtils.cleaningWornItems(character, wornItems, pct, factor)
    local mul = pct * factor
    local decTotal = 0
    local size = wornItems:size()
    local anyChanged = false

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
                if TABAS_BathingUtils.canBeWetClothing(item) then
                    if item:getWetness() < 100 then
                        item:setWetness(100)
                        changed = true
                    end
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
                anyChanged = true
                syncItemFields(character, item)
            end
        end
    end

    return decTotal, anyChanged
end

function TABAS_BathingUtils.washCleansedBody(character, wornItems, pct, grimeWashFactor, makeOff)
    if isClient() then
        if character then
            local bodyCleansed = TABAS_BathingUtils.cleaningBody(character, pct, 1)
            if bodyCleansed > 0 then
                character:resetModelNextFrame()
            end
        end
        local args = { pct = pct, factor = grimeWashFactor, makeOff = makeOff }
        sendClientCommand("tabas_bathing", "washCleansedBody", args)
        return
    end
    if not character then return end

    wornItems = wornItems or character:getWornItems()

    local cleansed = 0.3 -- This value is used to tainted tub water after the character leaves the bath. It is added each time the character washes off blood and dirt.
    local bodyChanged = false
    local wornChanged = false
    local makeupRemoved = 0

    local bodyCleansed = TABAS_BathingUtils.cleaningBody(character, pct, 1)
    bodyChanged = bodyCleansed > 0
    cleansed = cleansed + bodyCleansed
    cleansed = cleansed + (TABAS_BathingUtils.cleaningGrime(character, pct, grimeWashFactor) * 0.3)

    local wornItemCount = wornItems and TABAS_Utils.countWornClothesAfterExclusions(wornItems) or 0
    if wornItemCount > 0 then
        local wornCleansed
        wornCleansed, wornChanged = TABAS_BathingUtils.cleaningWornItems(character, wornItems, pct, 1)
        cleansed = cleansed + wornCleansed
    end
    if makeOff then
        makeupRemoved = TABAS_BathingUtils.removeAllMakeup(character)
        cleansed = cleansed + makeupRemoved
    end

    local humanVisualChanged = bodyChanged or makeupRemoved > 0
    if humanVisualChanged then
        sendHumanVisual(character)
    end
    if wornChanged then
        syncVisuals(character)
    end
    if humanVisualChanged or wornChanged then
        character:resetModelNextFrame()
    end

    if not isServer() and (humanVisualChanged or wornChanged) then
        triggerEvent("OnClothingUpdated", character)
    end

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

function TABAS_BathingUtils.canBeWetClothing(item)
    if not item or not item:IsClothing() or item:isHidden() then
        return false
    end

    local bloodTypes = item:getBloodClothingType()
    if not bloodTypes or bloodTypes:isEmpty() then
        return false
    end

    local coveredParts = BloodClothingType.getCoveredParts(bloodTypes)
    return coveredParts and coveredParts:size() > 0
end

function TABAS_BathingUtils.wetWornItems(character, wornItems, increase)
    if not wornItems then return true end

    local count = 0
    for i=0, wornItems:size()-1 do
        local item = wornItems:get(i):getItem()
        if item and TABAS_BathingUtils.canBeWetClothing(item) then
            local wet = item:getWetness()
            if wet and wet < 95 then
                if not isClient() then
                    item:setWetness(math.min(100, wet + increase))
                    syncItemFields(character, item)
                end
                count = count + 1
            end
        end
    end

    if isClient() then
        if count > 0 then
            sendClientCommand("tabas_bathing", "wetWornItems", {increase = increase})
        end
        return count == 0
    end

    triggerEvent("OnClothingUpdated", character)
    return count == 0
end

return TABAS_BathingUtils
