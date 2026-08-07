require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISWashYourself"

TABAS_TakeShower = ISBaseTimedAction:derive("TABAS_TakeShower")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local WaterReader = require("TABAS_WaterReader")
local TABAS_Sounds = require("TABAS_Sounds")

local ACTION_VARIABLE = TABAS_AnimVariables["SHOWER"].Actions

local CONSUME_STEP_NORMAL = 0.5
local CONSUME_STEP_LOW = 0.1
local FULL_CONSUME_SECONDS = 60.0

local NOWATER_DELAY = 5.0
local HOT_CHEACK_INTERVAL = 2.0

local _isClient = isClient()
local _isServer = isServer()
local _isSinglePlayerMode = (not _isClient and not _isServer)

local debugPrint = function(str)
    TABAS_Utils.debugPrint("Take Shower", str)
end

function TABAS_TakeShower.getSoapsInInventory(character, remaining)
    local soapList = {}
    local total = remaining or 0
    if not character then return soapList, total end

    local inventory = character:getInventory()
    for soapType,_ in pairs(TABAS_Utils.SoapTypes) do
        local list = inventory:getItemsFromType(soapType, true)
        for i=0, list:size() - 1 do
            local item = list:get(i)
            if item and item:getCurrentUses() > 0 then
                soapList[#soapList + 1] = item
                total = total + item:getCurrentUses()
            end
        end
    end
    return soapList, total
end

function TABAS_TakeShower.getSoapsOnSquare(square, remaining)
    local soapList = {}
    local total = remaining or 0
    if not square then return soapList, total end

    local worldObjects = square:getWorldObjects()
    for i=0, worldObjects:size() - 1 do
        local item = worldObjects:get(i):getItem()
        if item and item:IsDrainable() and item:getCurrentUses() > 0 and TABAS_Utils.SoapTypes[item:getType()] then
            soapList[#soapList + 1] = item
            total = total + item:getCurrentUses()
        end
    end
    return soapList, total
end

function TABAS_TakeShower.getSoapIdsOnSquare(square, remaining)
    local soapList, total = TABAS_TakeShower.getSoapsOnSquare(square, remaining)
    local soapIds = {}
    for i=1, #soapList do
        soapIds[#soapIds + 1] = soapList[i]:getID()
    end
    return soapIds, total
end

function TABAS_TakeShower:refreshSoap()
    if not self.consumeSoap or self.consumeSoap <= 0 then
        self.soapList1 = {}
        self.soapList2 = {}
        self.useSoap = false
        self.grimeWashFactor = 0.75
        return
    end

    self.soapList1 = TABAS_TakeShower.getSoapsInInventory(self.character)
    self.soapList2 = TABAS_TakeShower.getSoapIdsOnSquare(self.square)
    self.useSoap = (#self.soapList1 > 0 or #self.soapList2 > 0)
    self.grimeWashFactor = self.useSoap and 0.95 or 0.75
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
    if not self.facingDir then
        self.facingDir = self:getFacingDir()
    end

    char:faceDirection(self.facingDir)
    if not self._delayOnes then
        self._delayOnes = true
        return true
    end

    return char:getDir() ~= self.facingDir or char:shouldBeTurning()
end

function TABAS_TakeShower:getFacingDir()
    if self.facing == "S" then return IsoDirections.N
    elseif self.facing == "E" then return IsoDirections.W
    elseif self.facing == "W" then return IsoDirections.E
    else return IsoDirections.S
    end
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

function TABAS_TakeShower:addShampooForm()
    if self.shampooForm then return end
    if not self.useSoap then
        TABAS_Utils.removeFakeWornItem(self.character, "BodyShampoo")
        return
    end

    TABAS_Utils.addFakeWornItem(self.character, "TABAS.ShampooForm", "BodyShampoo")
    debugPrint("Add ShampooForm")
    self.shampooForm = true
    self:consumesSoap()
end

function TABAS_TakeShower:removeShampooForm()
    if not self.shampooForm or self.removedForm then return end
    TABAS_Utils.removeFakeWornItem(self.character, "BodyShampoo")
    self.removedForm = true
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

function TABAS_TakeShower:consumeRemainingWater()
    -- if _isClient then return end
    if self._consumed then return 0 end
    if self.useInfinityWater or not self.waterObj or not self.showerObj then return 0 end
    if self.doneWashCount < 2 then return 0 end

    local remain = self.consumedWaterMax - self.consumedWaterTotal
    if remain <= 0 then
        self._consumed = true
        return 0
    end
    local consumed = WaterReader.consume(self.showerObj, remain)
    self.consumedWaterTotal = self.consumedWaterTotal + consumed
    self._consumed = true
    return consumed
end

function TABAS_TakeShower:waterConsumption(deltaSeconds)
    if self.useInfinityWater then return end
    if self.finished then return end
    if self.removeWaterNextFrame then
        self.removeWaterNextFrame = false
        self:removeWaterObject()
        return
    end
    if not self.waterObj then return end
    if not deltaSeconds or deltaSeconds <= 0 then return end

    local rate = self.consumedWaterMax / FULL_CONSUME_SECONDS
    self.perUsesWater = (self.perUsesWater or 0) + (rate * deltaSeconds)

    self._lastStep = self._lastStep or 0
    local step = self._consumeStep or CONSUME_STEP_NORMAL
    if (self.elapsed - self._lastStep) < step then return end
    self._lastStep = self.elapsed

    local required = self.perUsesWater
    if required <= 0 then return end

    local remainMax = self.consumedWaterMax - self.consumedWaterTotal
    if remainMax <= 0 then
        self.perUsesWater = 0
        return
    end

    local used = math.min(required, self.perUsesMax, remainMax)
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

    local remain = WaterReader.getWaterAmount(self.showerObj)
    self._consumeStep = (remain <= self.perUsesMax) and CONSUME_STEP_LOW or CONSUME_STEP_NORMAL
end

function TABAS_TakeShower:updateShower(tm)
    if self.finished then return end

    local nowMs = getTimestampMs()
    local deltaSeconds = 0
    if self.lastUpdateMs then
        deltaSeconds = (nowMs - self.lastUpdateMs) / 1000
        if deltaSeconds < 0 then
            deltaSeconds = 0
        elseif deltaSeconds > 2 then
            deltaSeconds = 2
        end
    end
    self.lastUpdateMs = nowMs
    self.elapsed = self.elapsed + deltaSeconds
    self:waterConsumption(deltaSeconds)
    if not self.waterObj then return end

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
end

function TABAS_TakeShower:update() -- CLIENT UPDATE
    if _isServer then return end
    if self.finished then return end

    local char = self.character
    local tm = TABAS_GameTimes.getMultiplier()

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

        if self.endCount == 0 then
            self.endCount = -1
            self:syncAnim({ ACTION = ACTION_VARIABLE.STOP})
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

    if self.started and not _isClient then
        self:updateShower(tm)
    end
end

function TABAS_TakeShower:setupModData(on)
    local md = self.character:getModData()
    md.tabas_IsBathing = on
    self.character:transmitModData()

    local smd = self.showerObj:getModData()
    smd.using = on and TABAS_Utils.getPlayerKey(self.character) or nil
    self.showerObj:transmitModData()
end

function TABAS_TakeShower:start()
    setGameSpeed(1)
    self.character:setIgnoreMovement(true)
    self.character:setIgnoreContextKey(true)
    self:setActionAnim("TABAS_TakeShower")
    self.action:setOverrideAnimation(true)
    self:syncAnim({ PERFORM=true, STARTED=false, ACTION=ACTION_VARIABLE.START })

    if _isSinglePlayerMode then
        self:setupModData(true)
    end

    if not _isServer then
        triggerEvent("OnBathingStart", self.character, "SHOWER", self)
    end
end

function TABAS_TakeShower:serverStart()
    debugPrint("ServerStart")
    self:refreshSoap()
    TABAS_AnimVariables.setVariables(self.character, "SHOWER", { CLEAR = true })
    self:setupModData(true)

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

            if (_isClient or _isSinglePlayerMode) then
                self:syncAnim({ ACTION = ACTION_VARIABLE.WASH, WASH_PART = "Hand" })
            end

            if (_isServer or _isSinglePlayerMode) then
                self:addWaterObject()
            end
        end

    elseif event == "TABAS_ShowerUpdate" and _isServer then -- update (This event is server only)
        if self.character:getVariableBoolean("TABAS_ShowerEnded") then
            debugPrint("Shower Ended Server")
            self.finished = true
            self.netAction:forceComplete()
            return
        end

        self:updateShower(1)

    elseif parameter == "TABAS_WashPartFinished=true" then
        if self.stopping then return end

        local part = table.remove(self.washParts, 1)
        if part then
            self:syncAnim({ WASH_PART_FINISHED = false, WASH_PART = part })
        else
            self:syncAnim({ WASH_PART_FINISHED = false, WASH_PART = "Face" })
        end
        if self.endCount > 0 then -- count down for action end.
            self.endCount = self.endCount - 1
        end

    elseif parameter == "TABAS_ShowerEnded=true" then
        debugPrint("Shower Ended")
        if _isClient then
            sendClientCommand("tabas_bathing", "showerEnded", {})
        end
        self.finished = true
        self:forceComplete()

    elseif parameter == "TABAS_ShowerStopping=true" then
        debugPrint("TABAS_ShowerStopping")
        self.stopping = true

    elseif event == "TABAS_WashCleansed" then
        if self.doneWashCount < 2 then
            self.doneWashCount = self.doneWashCount + 1
            self:addShampooForm()
            local pct = self.doneWashCount / 2
            TABAS_BathingUtils.washCleansedBody(self.character, nil, pct, self.grimeWashFactor, self.makeOff)
            debugPrint("Wash Cleansing: count = " ..  self.doneWashCount)
        end
        if self.doneWashCount >= 2 then
            self:removeShampooForm()
        end
    elseif event == "TABAS_PlaySound" and not _isServer then
        if parameter ~= "" then
            TABAS_Sounds.playPlayerSound(self.character, parameter)
        end

    end
end

function TABAS_TakeShower:stop()
    self:removeShampooForm()
    TABAS_AnimVariables.clearVariables(self.character, "SHOWER")
    self.character:setIgnoreMovement(false)
    self.character:setIgnoreContextKey(false)

    triggerEvent("OnBathingEnd", self.character)
    if not _isClient then
        self:serverStop()
    end
    ISBaseTimedAction.stop(self)
end

function TABAS_TakeShower:serverStop()
    -- debugPrint("server stop")
    self:removeShampooForm()
    self:removeWaterObject()
    self:setupModData(nil)
end

function TABAS_TakeShower:perform()
    setGameSpeed(1)
    TABAS_AnimVariables.clearVariables(self.character, "SHOWER")
    self.character:PlayAnim("Idle")
    self.character:setIgnoreMovement(false)
    self.character:setIgnoreContextKey(false)
    triggerEvent("OnBathingEnd", self.character)
    ISBaseTimedAction.perform(self)
end

function TABAS_TakeShower:complete()
    -- debugPrint("complete")
    local remainingConsumed = self:consumeRemainingWater()
    debugPrint(string.format(
        "Water consumed: total=%.3fL / max=%.3fL, remaining=%.3fL, infinity=%s",
        self.consumedWaterTotal or 0,
        self.consumedWaterMax or 0,
        remainingConsumed or 0,
        tostring(self.useInfinityWater)
    ))
    self:removeWaterObject()

    self:removeShampooForm()

    self:setupModData(nil)
    return true
end

function TABAS_TakeShower:adjustMaxTime(maxTime)
    return maxTime
end

function TABAS_TakeShower:getDuration()
    self.endCount = 4 -- Action end time is determined by count of wash animations.
    return -1
    -- return 1750
end

function TABAS_TakeShower:new(character, showerObj, square, facing, soapList1, soapList2, comsumeSoap, makeOff, useHot, isInTub)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.square = square
    o.showerObj = showerObj
    o.facing = facing

    o.soapList1 = soapList1 or {}
    o.soapList2 = soapList2 or {}
    o.consumeSoap = comsumeSoap or ISWashYourself.GetRequiredSoap(character)
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

    o.washParts = TABAS_AnimVariables.getWashParts("SHOWER", character:isFemale(), true)

    local amount = WaterReader.getWaterAmount(showerObj)
    o.useInfinityWater = amount >= 9999
    -- runtime flags
    o.perUsesWater = 0
    o.perUsesMax = 15 -- (L)
    o.consumedWaterTotal = 0
    o.consumedWaterMax = SandboxVars.TakeABathAndShower.ShowerConsumeWater -- default 80

    o.noWaterActionDelay = 0

    -- local state
    o.started = false
    o.stopping = false
    o.finished = false
    o.elapsed = 0
    o.lastUpdateMs = nil

    o.doneWashCount = 0
    o.shampooForm = false
    o.removedForm = false
    o.hotCheckTimer = 0

    -- TimedAction settings
    o.useProgressBar = false
    o.ignoreHandsWounds = true
    o.caloriesModifier = 0.2
    return o
end
