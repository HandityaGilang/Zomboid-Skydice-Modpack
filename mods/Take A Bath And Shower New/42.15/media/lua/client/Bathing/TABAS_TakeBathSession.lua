local TABAS_TakeBathSession = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_GameTimes = require("TABAS_GameTimes")

TABAS_TakeBathSession.instances = {}

function TABAS_TakeBathSession:initialise(character)
    local playerKey = TABAS_Utils.getPlayerKey(character)
    self.instances[playerKey] = self
end

function TABAS_TakeBathSession:get(character)
    if not character then return end
    local playerKey = TABAS_Utils.getPlayerKey(character)
    return self.instances[playerKey]
end

function TABAS_TakeBathSession:ended(character)
    if not character then return end
    local playerKey = TABAS_Utils.getPlayerKey(character)
    self.instances[playerKey] = nil
    return true
end

function TABAS_TakeBathSession:getRemainingMinutes()
    if not self.endH or self.endH <= 0 then return 0 end
    local nowH = TABAS_GameTimes.getWorldAgeHours()
    local remain = (self.endH - nowH) * 60
    if remain < 0 then remain = 0 end
    return remain
end

function TABAS_TakeBathSession:isValid()
    local char = self.character
    if not char
        or char:isDead()
        or char:isWalking()
        or char:getVehicle() ~= nil
        or char:isSitOnGround()
        or char:isSittingOnFurniture()
        or char:isBumped()
        or char:hasHitReaction()
        or char:isOnFloor()
        or char:isKnockedDown()
        or char:isDeathDragDown() then
        return false
    end
    local tfc_Base = self:getTfc()
    return tfc_Base and tfc_Base:hasFluid()
end

function TABAS_TakeBathSession:getTfc()
    local tfc_Base = self.tfc_Base
    if not tfc_Base then
        local sq = self.baseSq
        tfc_Base = TFC_Utils.getTfcBaseOnClient(sq:getX(), sq:getY(), sq:getZ())
        self.tfc_Base = tfc_Base
    end
    return tfc_Base
end

function TABAS_TakeBathSession:new(character, bathObj, prepSq, climbSq, makeOff, plannedMinutes, isAutoMode, facingDir, exitTowel)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o:initialise(character)

    local playerNum = character:getPlayerNum()

    o.character = character
    o.facingDir = facingDir or character:getForwardIsoDirection()
    o.bathObj = bathObj
    o.plannedMinutes = plannedMinutes or 0
    o.isAutoMode = isAutoMode == true
    o.startH = TABAS_GameTimes.getWorldAgeHours()
    o.endH = o.isAutoMode and (o.startH + (o.plannedMinutes / 60)) or 0

    o.baseSq = bathObj:getSquare()
    o.prepSq = prepSq
    o.climbSq = climbSq

    o.makeOff = makeOff
    o.exitTowel = exitTowel
    o.washCount = 0
    o.autoWashTargetCount = 2
    o.wetTimeMax = 900
    o.bathingWetTime = 0
    o.wetEligibleSec = 0
    o.consumedWater = 25
    o.gaze = TABAS_BathingUtils.newGazeState(playerNum)
    o.comfort = TABAS_BathingUtils.newComfortState(playerNum)
    o.comfortReady = false
    o.comfortEligibleSec = 0
    o.headLook = {h=0, v=0}
    o.sounds = {}

    o.autoStanceEnabled = true
    o.autoExtEnabled = true
    o.curStance = character:getVariableString("TABAS_BathStance")
    o.pendingNotAllowedSay = false
    o.notAllowedSayCooldownUntilMs = nil

    o._idleStartMs = nil
    o._nextStanceDelayMs = nil
    o._nextExtDelayMs = nil
    o._lastExt = nil
    o._lastBathStateUpdateMs = nil
    o._lastComfortUpdateMs = nil

    o.isStopping = false
    o.isFinished = false

    return o
end

return TABAS_TakeBathSession
