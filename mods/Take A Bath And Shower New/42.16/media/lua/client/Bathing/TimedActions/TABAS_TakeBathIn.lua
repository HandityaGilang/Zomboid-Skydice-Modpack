require "TimedActions/ISBaseTimedAction"

TABAS_TakeBathIn = ISBaseTimedAction:derive("TABAS_TakeBathIn")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_Sounds = require("TABAS_Sounds")
local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")

function TABAS_TakeBathIn:isValid()
    if self.baseSq ~= self.character:getCurrentSquare() then
        return false
    end
    if not self.tfc_Base then
        self.tfc_Base = TFC_Utils.getTfcBaseOnClient(self.baseSq:getX(), self.baseSq:getY(), self.baseSq:getZ(), self.bathObj)
    end
    return self.tfc_Base and self.tfc_Base:canTakeBath()
end

function TABAS_TakeBathIn:waitToStart()
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

function TABAS_TakeBathIn:getFacingDir()
    local dir = self.bathObj:getFacing()
    local curSq = self.character:getCurrentSquare()
    if curSq == self.bathObj:getSquare()then
        return dir
    else
        return dir:Rot180()
    end
end

function TABAS_TakeBathIn:start()
    local omd = self.bathObj:getModData()
    omd.using = TABAS_Utils.getPlayerKey(self.character)
    self.bathObj:transmitModData()

    TABAS_AnimVariables.syncAnim(self.character, "BATH", { PERFORM = true }, true)
    TABAS_BathingUtils.setBathingSuppression(self.character, true)
    self:setActionAnim("TABAS_BathIn")
end

function TABAS_TakeBathIn:stop()
    ISBaseTimedAction.stop(self)
end

function TABAS_TakeBathIn:animEvent(event, parameter)
    if event == "TABAS_PlaySound" then
        if self.tfc_Base and self.tfc_Base:hasFluid() then
            if self.tfc_Base:isLowWater() then
                TABAS_Sounds.playPlayerSound(self.character, "tabas_bath_wave01")
            else
                TABAS_Sounds.playPlayerSound(self.character, "tabas_bath_in")
            end
        else
            TABAS_Sounds.playPlayerSound(self.character, "SurfaceSitDown")
        end
    elseif parameter == "TABAS_BathStarted=true" then
        TABAS_AnimVariables.syncAnim(self.character, "BATH", {STARTED = true, STANCE = "Idle" }, true)
        self:forceComplete()
    end
end

function TABAS_TakeBathIn:perform()
    local session = TABAS_TakeBathSession:new(self.character, self.bathObj, self.prepSq, self.climbSq, self.makeOff, self.bathTime, self.isAutoMode, self.facingDir, self.exitTowel)
    triggerEvent("OnBathingStart", self.character, "BATH", session)
    ISBaseTimedAction.perform(self)
end

function TABAS_TakeBathIn:getDuration()
    return -1
end

function TABAS_TakeBathIn:new(character, bathObj, prepSq, climbSq, makeOff, bathTime, isAutoMode, exitTowel)
    local o = ISBaseTimedAction.new(self, character)
    o.bathObj = bathObj
    o.baseSq = bathObj:getSquare()
    o.prepSq = prepSq
    o.climbSq = climbSq
    o.makeOff = makeOff or false
    o.bathTime = bathTime or 0
    o.isAutoMode = isAutoMode == true
    o.exitTowel = exitTowel
    o.maxTime = o:getDuration()

    -- TimedAction settings
    o.useProgressBar = false
    o.stopOnWalk = false
    o.stopOnRun  = false
    o.stopOnAim  = false
    o.ignoreHandsWounds = true
    o.caloriesModifier = 0.2
    return o
end
