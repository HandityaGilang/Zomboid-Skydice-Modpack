require "TimedActions/ISBaseTimedAction"

TABAS_TakeShower = ISBaseTimedAction:derive("TABAS_TakeShower")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local WaterReader = require("TABAS_WaterReader")
local TABAS_Sounds = require("TABAS_Sounds")

local ACTION_VARIABLE = TABAS_AnimVariables["SHOWER"].Actions

local CONSUME_STEP_NORMAL = 0.08
local CONSUME_STEP_LOW = 0.03

local ADD_FORM_DELTA = 0.2
local REMOVE_FORM_DELTA = 0.75

local NOWATER_DELAY = 5.0
local HOT_CHEACK_INTERVAL = 2.0
local WORN_CHEACK_INTERVAL = 2.0
local WET_END_MAX_DELTA = 0.6

-- It is a remaining action-time margin (same unit as maxTime)
-- tuned empirically so ShowerStop animation always finishes
local FINISH_PERIOD = 150

local _isClient = isClient()
local _isServer = isServer()
local _isSinglePlayerMode = (not _isClient and not _isServer)

local debugPrint = function(str)
    TABAS_Utils.debugPrint("Take Shower", str)
end

function TABAS_TakeShower:isValid()
    return self.square ~= nil and self.showerObj ~= nil
end

function TABAS_TakeShower:waitToStart()
    local char = self.character
    if not char then return false end

    if char:isAiming() then char:nullifyAiming() end
    local wasSneaking = char:isSneaking()
    if wasSneaking then char:setSneaking(false) end
    if TABAS_Utils.waitFrames(self, 50, wasSneaking) then
        return true
    end
    local wasWalking = char:isWalking() or char:isTurning()
    if TABAS_Utils.waitFrames(self, 30, wasWalking) then
        return true
    end
    if self.facing == "S" then char:faceDirection(IsoDirections.N)
    elseif self.facing == "E" then char:faceDirection(IsoDirections.W)
    elseif self.facing == "W" then char:faceDirection(IsoDirections.E)
    elseif self.facing == "N" then char:faceDirection(IsoDirections.S)
    end
    return char:shouldBeTurning()
end

function TABAS_TakeShower:addWaterObject()
    if self.waterObj then
        debugPrint("Already addeed water object!")
        return
    end
    -- create object
    local obj = IsoObject.new(self.square, self.waterSprite, "ShowerWater")
    self.square:AddSpecialObject(obj)

    local md = obj:getModData()
    md.facing = self.facing
    md.isHotWater = self.isHotWater
    md.owner = self.character:getOnlineID()

    obj:transmitCompleteItemToClients()
    obj:transmitModData()
    triggerEvent("OnObjectAdded", obj)
    self.waterObj = obj
    debugPrint("Added shower water object!")
end

function TABAS_TakeShower:removeWaterObject()
    if self.waterObj and self.square then
        self.square:transmitRemoveItemFromSquareOnClients(self.waterObj)
        self.square:RemoveTileObject(self.waterObj)
        self.waterObj = nil
        debugPrint("Removed shower water object!")
    end
end

function TABAS_TakeShower:consumesSoap()
    -- if _isClient then return end
    local totalUses = self.consumeSoap
    local function consumes(soap)
        if not soap or totalUses <= 0 then return end
        while totalUses > 0 and soap:getCurrentUses() > 0 do
            soap:UseAndSync()
            totalUses = totalUses - 1
        end
    end
    -- use sopa in inventory
    for i=1, #self.soapList1 do
        if totalUses <= 0 then break end
        consumes(self.soapList1[i])
    end
    if totalUses <= 0 then return end

    -- use soap on floor
    local worldObjects = self.square:getWorldObjects()
    for i=1, #self.soapList2 do
        if totalUses <= 0 then break end

        local id = self.soapList2[i]
        for j=0, worldObjects:size() - 1 do
            local soap = worldObjects:get(j):getItem()
            if soap and soap:getID() == id then
                consumes(soap)
                break
            end
        end
    end
end

function TABAS_TakeShower:consumeRemainingWater(progress)
    -- if _isClient then return end
    if self._consumed then return 0 end
    if self.useInfinityWater or not self.waterObj or not self.showerObj then return 0 end

    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end

    local consumeMax = self.consumedWaterMax * progress
    local remain = consumeMax - self.consumedWaterTotal
    if remain <= 0 then
        self._consumed = true
        return 0
    end
    local consumed = WaterReader.consume(self.showerObj, remain)
    self.consumedWaterTotal = self.consumedWaterTotal + consumed
    self._consumed = true
    return consumed
end

function TABAS_TakeShower:waterConsumption(dt)
    if self.useInfinityWater then return end
    if self.finished then return end
    if self.removeWaterNextFrame then
        self.removeWaterNextFrame = false
        self:removeWaterObject()
        return
    end
    if not self.waterObj then return end

    local targetUsed = self.consumedWaterMax * dt
    local add = targetUsed - (self.usedWater or 0)
    if add > 0 then
        self.usedWater = targetUsed
        self.perUsesWater = (self.perUsesWater or 0) + add
    end

    self._lastStep = self._lastStep or 0
    local step = self._consumeStep or CONSUME_STEP_NORMAL
    if (dt - self._lastStep) < step then return end
    self._lastStep = dt

    local required = self.perUsesWater
    if required <= 0 then return end

    local used = math.min(required, self.perUsesMax)
    self.perUsesWater = required - used

    local consumed = WaterReader.consume(self.showerObj, used)

    -- local eps = math.max(1e-6, math.abs(used) * 1e-8)
    local eps = 1e-6
    if math.abs(consumed - used) <= eps then
        consumed = used
    end

    self.consumedWaterTotal = self.consumedWaterTotal + consumed

    if consumed < used then
        self.perUsesWater = 0
        self.removeWaterNextFrame = true
        self.isHotWater = false
        return
    end

    local remain = self.showerObj:getFluidAmount()
    self._consumeStep = (remain <= self.perUsesMax) and CONSUME_STEP_LOW or CONSUME_STEP_NORMAL
end

function TABAS_TakeShower:updateShower(dt, tm)
    if self.finished then return end

    self:waterConsumption(dt)
    if not self.waterObj then return end

    -- Shampoo form
    if not self.shampooForm and dt > ADD_FORM_DELTA then
        if self.useSoap then
            TABAS_Utils.addFakeWornItem(self.character, "TABAS.ShampooForm", "BodyShampoo")
            debugPrint("Add ShampooForm")
            self.shampooForm = true
            self:consumesSoap()
        else
            TABAS_Utils.removeFakeWornItem(self.character, "BodyShampoo")
        end
    end
    if dt > REMOVE_FORM_DELTA and self.shampooForm and not self.removedForm then
        TABAS_Utils.removeFakeWornItem(self.character, "BodyShampoo")
        self.removedForm = true
    end
    if self.wornItemCount > 0 and not self.wetWornFinished then
        if self.wetWornInterval > WORN_CHEACK_INTERVAL then
            self.wetWornInterval = 0
            self.wetWornFinished = TABAS_BathingUtils.wetWornItems(self.character, self.wornItems)
        else
            self.wetWornInterval = self.wetWornInterval + tm
        end
    end
    -- hot water check
    if self.useHot then
        if self.hotCheckTimer < HOT_CHEACK_INTERVAL then
            self.hotCheckTimer = self.hotCheckTimer + tm
        else
            self.hotCheckTimer = 0
            local canHot = TABAS_Iso.canHot(self.showerObj)
            local smd = self.showerObj:getModData()
            local temp = smd.idealTemperature or self.waterTemp or 40
            local nowHot = self.useHot and canHot and (temp > 36)
            self.waterTemp = temp
            if self.isHotWater ~= nowHot then
                self.isHotWater = nowHot
                smd.isHotWater = self.isHotWater
                self.showerObj:transmitModData()
            end
        end
    end
    -- Bathing wet
    local newWet = (dt >= WET_END_MAX_DELTA) and self.wetTimeMax or math.floor(self.wetTimeMax * (dt / 0.6) + 0.5)
    if newWet > self.bathingWetTime then
        self.bathingWetTime = newWet
    end
end

function TABAS_TakeShower:update() -- CLIENT UPDATE
    if self.finished then return end

    local char = self.character
    local jobDelta = self:getJobDelta()
    local nowMs = getTimestampMs()
    local tm = TABAS_GameTimes.getMultiplier()
    self.finalProgress = jobDelta

    if not self.stopping then
        if (char:pressedMovement(true)) then -- Stop trigger (movement keys)
            if self.started then
                -- This case, self.stopping and "TABAS_ShowerEnded" variable is triggered by an action anim event.
                self:syncAnim({ ACTION = ACTION_VARIABLE.STOP})
                return
            else
                self:syncAnim({ ENDED = true})
                return -- End immediately
            end
        end
        if self.noWaterActionDelay == 0 and self.started and not self.showerObj:hasFluid() then
            self.noWaterActionDelay = 1
            debugPrint("No Water Comes Check Start!")
        end

        -- End Action
        local remainProgress = 1.0 - jobDelta
        local finishMargin = FINISH_PERIOD / self.maxTime
        if remainProgress < finishMargin and not self.finished then
            self:syncAnim({ ACTION = ACTION_VARIABLE.STOP})
            if not self.completed then
                self.completed = true
                if _isClient then
                    char:getModData().tabas_ShowerCompleted = true
                    char:transmitModData()
                end
            end
        end
    end

    if self.noWaterActionDelay > 0 then
        self.noWaterActionDelay = self.noWaterActionDelay + tm
        if self.noWaterActionDelay > NOWATER_DELAY then
            self.noWaterActionDelay = 0
            if not self.showerObj:hasFluid() then
                self:syncAnim({ ACTION = ACTION_VARIABLE.NO_WATER})
                char:Say(getText("IGUI_TABAS_NoWaterComes"))
                debugPrint("No Water Comes Done!")
                self.noWaterActionDelay = -1
            end
        end
    end

    if self.started then
        -- Moodle and Nomal Wet
        if not self.comfortReady then
            self.comfortReady = TABAS_BathingUtils.hasBathingElapsed(self.character:getModData(), TABAS_BathingUtils.getBathingComfortDelaySec())
        end
        if self.comfortReady then
            local worldTempe = TABAS_Utils.getWorldTemperature()
            self.comfort = TABAS_BathingUtils.updateComfortState(self.character, self.comfort, worldTempe, self.isHotWater)
        end
        -- Feeling gaze
        self.gaze = TABAS_BathingUtils.feelingGaze(char, self.gaze, nowMs, false)

        if not _isClient then
            self:updateShower(jobDelta, tm)
        end
    end
end

function TABAS_TakeShower:setupModData(on, completed)
    local md = self.character:getModData()
    md.tabas_IsBathing = on
    md.tabas_BathingStartH = on and TABAS_GameTimes.getWorldAgeHours() or nil

    md.tabas_ShowerEnded = nil
    md.tabas_ShowerCompleted = nil
    md.tabas_FeelingGaze = nil
    md.tabas_Comforted = nil
    if on then
        local smd = self.showerObj:getModData()
        smd.using = true
        smd.user = TABAS_Utils.getPlayerKey(self.character)
        self.showerObj:transmitModData()
    else
        TABAS_BathingUtils.setBathingWetEndH(self.character, self.bathingWetTime, completed, true, false)
    end
    self.character:transmitModData()
end

function TABAS_TakeShower:start()
    setGameSpeed(1)
    self.character:setIgnoreMovement(true)
    self.character:setIgnoreContextKey(true)
    self:setActionAnim("TABAS_TakeShower")
    self.action:setOverrideAnimation(true)
    self:syncAnim({ PERFORM=true, STARTED=false, ACTION=ACTION_VARIABLE.START })

    if _isSinglePlayerMode then
        self:setupModData(true, false)
        self.wornItems = self.character:getWornItems()
        self.wornItemCount = TABAS_Utils.getWornClothesCountExcluded(self.wornItems, true)
    end
end

function TABAS_TakeShower:serverStart()
    debugPrint("ServerStart")
    self:setupModData(true, false)
    self.wornItems = self.character:getWornItems()
    self.wornItemCount = TABAS_Utils.getWornClothesCountExcluded(self.wornItems, true)

    emulateAnimEventOnce(self.netAction, 1000, nil, "TABAS_ShowerStarted=true")
    emulateAnimEvent(self.netAction, 100, "TABAS_ShowerUpdate", nil)
end

function TABAS_TakeShower:syncAnim(args)
    TABAS_AnimVariables.syncAnim(self.character, "SHOWER", args, true)
end

function TABAS_TakeShower:animEvent(event, parameter)
    if self.finished then return end

    if parameter == "TABAS_ShowerStarted=true" then
        debugPrint("received animEvent >> ShowerStarted")
        if not self.started then
            self.started = true
            self.progressStartMs = getTimestampMs()

            if (_isClient or _isSinglePlayerMode) then
                self:syncAnim({ ACTION = ACTION_VARIABLE.WASH, WASH_PART = "Hand" })
            end

            if (_isServer or _isSinglePlayerMode) then
                self:addWaterObject()
                TABAS_BathingUtils.startBathingBenefit(self.character, "SHOWER", self.square:getX(), self.square:getY(), self.square:getZ())
            end
        end

    elseif event == "TABAS_ShowerUpdate" then -- update (This event is server only)
        local progress = self.netAction:getProgress()
        self.finalProgress = progress
        local md = self.character:getModData()
        -- finish form mod data
        if md.tabas_ShowerEnded then
            -- debugPrint("finished")
            self.completed = (md.tabas_ShowerCompleted == true)
            self.finalProgress = self.completed and 1 or progress
            self.finished = true
            self.netAction:forceComplete()
            return
        end

        self:updateShower(progress, 1)

    elseif parameter == "TABAS_WashPartFinished=true" then
        if self.stopping then return end

        local part = table.remove(self.washParts, 1)
        if part then
            self:syncAnim({ WASH_PART_FINISHED = false, WASH_PART = part })
        else
            self:syncAnim({ WASH_PART_FINISHED = false, WASH_PART = "Face" })
        end

    elseif parameter == "TABAS_ShowerEnded=true" then
        debugPrint("Shower Ended")
        local md = self.character:getModData()
        md.tabas_ShowerEnded = true
        self.character:transmitModData()
        self.finished = true
        self:forceComplete()

    elseif parameter == "TABAS_ShowerStopping=true" then
        debugPrint("TABAS_ShowerStopping")
        self.stopping = true

    elseif event == "TABAS_WashCleansed" then
        if self.doneWashCount < 2 then
            self.doneWashCount = self.doneWashCount + 1
            local pct = self.doneWashCount / 2
            TABAS_BathingUtils.washCleansedBody(self.character, self.wornItems, pct, self.grimeWashFactor, self.makeOff)
            debugPrint("Wash Cleansing: count = " ..  self.doneWashCount)
        end

    elseif event == "TABAS_PlaySound" and not _isServer then
        if parameter ~= "" then
            TABAS_Sounds.playPlayerSound(self.character, parameter)
        end

    end
end

function TABAS_TakeShower:stop()
    TABAS_AnimVariables.clearVariables(self.character, "SHOWER")
    self.character:setIgnoreMovement(false)
    self.character:setIgnoreContextKey(false)

    if not _isClient then
        self:serverStop()
    end
    ISBaseTimedAction.stop(self)
end

function TABAS_TakeShower:serverStop()
    -- debugPrint("server stop")
    self:removeWaterObject()
    self:setupModData(nil, false)
    TABAS_BathingUtils.stopBathingBenefit(self.character)
end

function TABAS_TakeShower:perform()
    setGameSpeed(1)
    TABAS_AnimVariables.clearVariables(self.character, "SHOWER")
    self.character:PlayAnim("Idle")
    self.character:setIgnoreMovement(false)
    self.character:setIgnoreContextKey(false)

    -- There mod data not synced to server.
    ISBaseTimedAction.perform(self)
end

function TABAS_TakeShower:complete()
    -- debugPrint("complete")
    local progress = self.finalProgress
    if self.completed then progress = 1 end
    self:consumeRemainingWater(progress)
    self:removeWaterObject()

    -- if self.shampooForm and not self.removedForm then
    --     TABAS_Utils.removeFakeWornItem(self.character, "BodyShampoo")
    -- end

    TABAS_BathingUtils.stopBathingBenefit(self.character)
    self:setupModData(nil, true)
    return true
end

function TABAS_TakeShower:adjustMaxTime(maxTime)
    return maxTime
end

function TABAS_TakeShower:getDuration()
    return 1750
end

function TABAS_TakeShower:new(character, showerObj, square, facing, soapList1, soapList2, comsumeSoap, makeOff, useHot, isInTub)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.square = square
    o.showerObj = showerObj
    o.facing = facing

    o.soapList1 = soapList1 or {}
    o.soapList2 = soapList2 or {}
    o.consumeSoap = comsumeSoap or 0
    o.useSoap = (#o.soapList1 > 0 or #o.soapList2 > 0) and o.consumeSoap > 0
    o.grimeWashFactor = o.useSoap and 0.95 or 0.75
    o.makeOff = makeOff

    o.useHot = useHot
    o.waterTemp = showerObj:getModData().idealTemperature or 40.0
    o.isHotWater = true
    -- shower water stats
    if useHot then
        if not TABAS_Iso.canHot(showerObj) then
            o.waterTemp = 22.0
            o.isHotWater = false
        elseif o.waterTemp < 40 then
            o.isHotWater = false
        end
    else
        o.waterTemp = 22.0
        o.isHotWater = false
    end
    o.isInTub = isInTub

    -- water fx sprite base (server spawns water object; client animates it by FX module)
    o.waterObj = nil
    o.waterSprite = TABAS_Iso.getSpritesTable("ShowerBlank", "sprite" .. o.facing)

    o.maxTime = o:getDuration()

    local playerNum = character:getPlayerNum()
    o.comfort = TABAS_BathingUtils.newComfortState(playerNum)
    o.comfortReady = false
    o.gaze = TABAS_BathingUtils.newGazeState(playerNum)

    o.washParts = TABAS_AnimVariables.getWashParts("SHOWER", character:isFemale(), true)

    local amount = WaterReader.getWaterAmount(showerObj)
    o.useInfinityWater = amount >= 9999
    -- runtime flags
    o.usedWater = 0
    o.perUsesWater = 0
    o.perUsesMax = 15 -- (L)
    o.consumedWaterTotal = 0
    o.consumedWaterMax = SandboxVars.TakeABathAndShower.ShowerConsumeWater -- default 80
    o.wetTimeMax = 600
    o.bathingWetTime = 0

    o.noWaterActionDelay = 0
    o.wetWornInterval = 0
    o.wetWornFinished = false

    -- local state
    o.started = false
    o.progressStartMs = 0
    o.stopping = false
    o.finished = false
    o.completed = false
    o.finalProgress = 0

    o.currentWashPart = false
    o.doneWashCount = 0
    o.shampooForm = false
    o.removedForm = false
    -- Initialize counters
    o.hotCheckTimer = 0

    -- TimedAction settings
    -- o.stopOnWalk = false
    -- o.stopOnRun  = false
    -- o.stopOnAim  = false
    o.ignoreHandsWounds = true
    o.caloriesModifier = 0.2
    return o
end
