if isClient() then return end

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

local SOUND_INTERVAL = 30
local PHASE_INTERVAL = 10

local PENDING_TFC_REMOVES = {}

local function confirmServerObject(v)
    local bath = TABAS_Iso.getBathObjectAt(v.x, v.y, v.z)
    if not bath or bath:isDestroyed() then
        v.bath = nil
        v.tfc  = nil
        return false
    end

    local tfc = TFC_Utils.getTfcBaseOnServer(v.x, v.y, v.z, bath)
    if not tfc then
        v.bath = nil
        v.tfc  = nil
        return false
    end

    v.bath = bath
    v.tfc  = tfc
    return true
end

local function clearActivatedRuntime(v)
    v._soundTick = nil
    v._phaseTick = nil
    v._lastState = nil
    v.phase = nil
    v.bath = nil
    v.tfc  = nil
end

local function hasRegisteredEntry(id)
    local gData = GetTFCSystemData()
    return gData and gData.Registered and gData.Registered[id] ~= nil
end

local function shouldUpdatePhase(v, force)
    if force then
        v._phaseTick = 0
        return true
    end
    v._phaseTick = (v._phaseTick or 0) + 1
    if v._phaseTick < PHASE_INTERVAL then
        return false
    end
    v._phaseTick = 0
    return true
end

local function tryAddWorldSound(v, radius, volume, stateChanged)
    if stateChanged then
        v._soundTick = 0
    else
        v._soundTick = (v._soundTick or 0) + 1
        if v._soundTick < SOUND_INTERVAL then return end
        v._soundTick = 0
    end

    WorldSoundManager.instance:addSoundRepeating(v.bath, v.x, v.y, v.z, radius, volume, false)
end

local lastDayLengthFill
local lastDayLengthEmpty
local cachedFillEnd
local cachedEmptyEnd

local function getFillEndAmount()
    local length = TABAS_GameTimes.getMinutesPerDay()
    if not cachedFillEnd or lastDayLengthFill ~= length then
        lastDayLengthFill = length
        cachedFillEnd = TFC_Utils.FillRate * 160 * (60 / length)
    end
    return cachedFillEnd
end

local function getEmptyEndAmount()
    local length = TABAS_GameTimes.getMinutesPerDay()
    if not cachedEmptyEnd or lastDayLengthEmpty ~= length then
        lastDayLengthEmpty = length
        cachedEmptyEnd = TFC_Utils.DrainRate * 200 * (60 / length)
    end
    return cachedEmptyEnd
end

local function setPhase(v, newPhase)
    if v.phase ~= newPhase then
        v.phase = newPhase
        return true
    end
    return false
end


local function tubWaterServerTick()
    local gData = GetTFCSystemData()
    local activated = gData.Activated
    local dirty = false

    for k, v in pairs(activated) do
        if not confirmServerObject(v) then
            if hasRegisteredEntry(k) then
                v.pendingWorld = true
            else
                clearActivatedRuntime(v)
                activated[k] = nil
                dirty = true
            end
        else
            if v.pendingWorld then
                v.pendingWorld = nil
                dirty = true
            end
            if not v.activate then
                clearActivatedRuntime(v)
                activated[k] = nil
                dirty = true
            else
                local stateChanged = (v._lastState ~= v.state)
                v._lastState = v.state
                if v.state == "fill" then
                    local amount = TFC_Utils.FillRate * TABAS_GameTimes.getMultiplier()
                    local fillFluid = v.tfc:getFillFluid()
                    if v.bath:hasFluid() and (not v.tfc:isFull()) and v.tfc:canAddFluid(fillFluid) then
                        v.bath:useFluid(amount)
                        v.tfc:addWater(amount)
                        local prevPhase = v.phase
                        if shouldUpdatePhase(v, stateChanged) then
                            local newPhase = (v.bath:getFluidAmount() <= getFillEndAmount()) and "runout" or "fill"
                            if setPhase(v, newPhase) then
                                dirty = true
                                TFC_Utils.noise("Fill Activate", k, newPhase)
                                if prevPhase ~= "runout" and newPhase == "runout" then
                                    v._phaseTick = 0
                                end
                            end
                        end
                        tryAddWorldSound(v, 20, 5, stateChanged)
                    else
                        clearActivatedRuntime(v)
                        activated[k] = nil
                        dirty = true
                    end
                elseif v.state == "empty" then
                    local amount = TFC_Utils.DrainRate * TABAS_GameTimes.getMultiplier()
                    if not v.tfc:isEmpty() then
                        v.tfc:removeFluid(amount)
                        local prevPhase = v.phase
                        if shouldUpdatePhase(v, stateChanged) then
                            local newPhase = (v.tfc:getAmount() <= getEmptyEndAmount()) and "finish" or "drain_loop"
                            if setPhase(v, newPhase) then
                                dirty = true
                                TFC_Utils.noise("Empty Activate", "phase => ", newPhase, k)
                                if prevPhase ~= "finish" and newPhase == "finish" then
                                    v._phaseTick = 0
                                end
                            end
                        end
                        tryAddWorldSound(v, 20, 5, stateChanged)
                    else
                        v.tfc:remove()
                        clearActivatedRuntime(v)
                        activated[k] = nil
                        dirty = true
                    end
                elseif v.state == "reheat" then
                    if TABAS_Iso.canHot(v.bath) then
                        local current = v.tfc:getWaterTemperature()
                        local ideal = v.tfc:getBathData("idealTemperature")
                        if current <= ideal then
                            v.tfc:setWaterTemperature(current + TFC_Utils.ReheatRate * TABAS_GameTimes.getMultiplier())
                            if setPhase(v, "reheat") then
                                dirty = true
                                TFC_Utils.noise("Reheat Activate", k)
                            end
                            tryAddWorldSound(v, 10, 1, stateChanged)
                        else
                            v.tfc:updateLastUpdate()
                            clearActivatedRuntime(v)
                            activated[k] = nil
                            dirty = true
                        end
                    else
                        clearActivatedRuntime(v)
                        activated[k] = nil
                        dirty = true
                    end
                else
                    -- unknown state
                    clearActivatedRuntime(v)
                    activated[k] = nil
                    dirty = true
                end
            end
        end
    end

    if dirty then
        TransmitTFCSystemData("tubWaterServerTick")
    end
end
Events.OnTick.Add(tubWaterServerTick)

local function lowerWaterTemperature()
    if not SandboxVars.TakeABathAndShower.WaterTemperatureConcept then return end

    local gData = GetTFCSystemData()
    local minTempe = 10
    local dirty = false
    for id, v in pairs(gData.Registered) do
        if v.temperature and v.temperature > minTempe then
            local lastUpdate = v.lastUpdate
            local m, h, d = TABAS_Utils.getDifferentialTime(lastUpdate)
            if h and h > 0 then
                local newTemperature = round(v.temperature - TFC_Utils.TubWaterCoolingPerHour, 4)
                v.temperature = newTemperature
                dirty = true
                local x, y, z = TFC_Utils.getCoordsById(id)
                if getCell():getGridSquare(x, y, z) then
                    local tfc_Base = TFC_Utils.getTfcBaseOnServer(x, y, z)
                    if tfc_Base then
                        tfc_Base:setWaterTemperature(newTemperature)
                    end
                end
                TFC_Utils.noise("Lower Water Temperature", v.temperature + TFC_Utils.TubWaterCoolingPerHour .. " >> " .. v.temperature  .. ". " .. tostring(id))
            end
        end
    end
    if dirty then
        TransmitTFCSystemData("lowerWaterTemperature")
    end
end
Events.EveryHours.Add(lowerWaterTemperature)


local function onWaterAmountChange(object, _prevAmount)
    if not object or not TFC_Utils.isValidTfcObject(object) then return end
    local square = object:getSquare()
    local bathObject = TABAS_Iso.getBathObjectOnSquare(square)
    if not bathObject then return end

    local tfc_Base = TFC_Utils.getTfcBaseOnServer(square:getX(), square:getY(), square:getZ(), bathObject)
    if tfc_Base then
        tfc_Base:setWaterData("amount", object:getFluidAmount())
        tfc_Base:updateWaterSprite()
        -- TFC_Utils.noise("onWaterAmountChange", "Done!")
    end
end
Events.OnWaterAmountChange.Add(onWaterAmountChange)


local function markPendedRemove(id)
    local gData = GetTFCSystemData()
    if not gData or not gData.Registered then return end

    local data = gData.Registered[id]
    if data and data.isLinked and data.mainId then
        id = data.mainId
        data = gData.Registered[id]
    end
    if not data then return end

    data.pendedRemove = true
    if data.linkedX and data.linkedY then
        local _, _, z = TFC_Utils.getCoordsById(id)
        local lid = TFC_Utils.getIdByCoords(data.linkedX, data.linkedY, z)
        if gData.Registered[lid] then
            gData.Registered[lid].pendedRemove = true
        end
    end

    if gData.Activated then
        gData.Activated[id] = nil
    end
    TransmitTFCSystemData("markPendedRemove")
end

local function queueTfcRemove(id, tfc_Base)
    if not id then return end
    local gData = GetTFCSystemData()
    local data = gData and gData.Registered and gData.Registered[id] or nil
    if data and data.isLinked and data.mainId then
        id = data.mainId
    end

    if PENDING_TFC_REMOVES[id] then return end
    markPendedRemove(id)

    local x, y, z = TFC_Utils.getCoordsById(id)
    PENDING_TFC_REMOVES[id] = {
        x = x,
        y = y,
        z = z,
        tfc = tfc_Base,
    }
    TFC_Utils.noise("Queue TFC Remove", id)
end

local function processPendingTfcRemoves()
    for id, v in pairs(PENDING_TFC_REMOVES) do
        local tfc_Base = v.tfc
        if not tfc_Base then
            local bathObject = TABAS_Iso.getBathObjectAt(v.x, v.y, v.z)
            if bathObject then
                tfc_Base = TFC_Utils.getTfcBaseOnServer(v.x, v.y, v.z, bathObject)
            end
        end

        if tfc_Base then
            tfc_Base:remove()
            TFC_Utils.noise("Pended Remove", id)
        else
            local gData = GetTFCSystemData()
            if gData and gData.Registered and gData.Registered[id] then
                gData.Registered[id].pendedRemove = true
                TransmitTFCSystemData("processPendingTfcRemoves")
            end
        end
        PENDING_TFC_REMOVES[id] = nil
    end
end
Events.OnTick.Add(processPendingTfcRemoves)

local function onObjectAboutToBeRemoved(object)
    if not object or not TABAS_Iso.isBathObject(object) then return end

    local square = object:getSquare()
    if not square then return end

    local id = TFC_Utils.getRegisterdIdFromSquare(square, true)
    if not id then return end

    local x, y, z = TFC_Utils.getCoordsById(id)
    local bathObject = TABAS_Iso.getBathObjectAt(x, y, z) or object
    local tfc_Base = TFC_Utils.getTfcBaseOnServer(x, y, z, bathObject)
    if tfc_Base then
        queueTfcRemove(id, tfc_Base)
    end
end
Events.OnObjectAboutToBeRemoved.Add(onObjectAboutToBeRemoved)


local function onLoadGridsquare(square)
    local gData = GetTFCSystemData()
    if not TFC_Utils.hasTfcData(square) then return end

    -- for id, _ in pairs(bucket) do
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local data = TFC_Utils.getTFCData(x, y, z, "Registered")
    if not data then return end

    local bathObj = TABAS_Iso.getBathObjectAt(x, y, z)
    local tfc_Base = TFC_Utils.getTfcBaseOnServer(x, y, z, bathObj)
    if not tfc_Base then return end

    if data.pendedRemove then
        tfc_Base:remove()
        TFC_Utils.noise("Pended Remove", "Done!")
    else
        if not tfc_Base:hasTfc() then return end

        local changed = false
        local keys = TFC_Utils.getObjectModDataKeys()
        for i = 1, #keys do
            local k = keys[i]
            if data[k] ~= nil and tfc_Base:getWaterData(k) ~= data[k] then
                tfc_Base:setWaterData(k, data[k], false)
                changed = true
            end
        end

        if changed then
            tfc_Base:updateWaterSprite()
            tfc_Base:updateHotSteamOverlay()
            tfc_Base.tfcObject:transmitModData()
            if tfc_Base.linkedTfcObject then
                tfc_Base.linkedTfcObject:transmitModData()
            end
        end
    end
end
Events.LoadGridsquare.Add(onLoadGridsquare)
