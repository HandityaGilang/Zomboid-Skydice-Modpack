if isClient() then return end

local TABAS_BathingBenefitDriver = {}

TABAS_BathingBenefitDriver.instances = TABAS_BathingBenefitDriver.instances or {}

local TABAS_BathingBenefits = require("Bathing/TABAS_BathingBenefits")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

function TABAS_BathingBenefitDriver.stop(player, removeModData)
    local key = TABAS_Utils.getPlayerKey(player)
    TABAS_BathingBenefitDriver.instances[key] = nil
    local md = player:getModData()
    if not md then return end

    if removeModData and  md.tabas_BathingBenefit then
        md.tabas_BathingBenefit = nil
    end
end

function TABAS_BathingBenefitDriver.getInstance(player, benefitData)
    local key = TABAS_Utils.getPlayerKey(player)
    local inst = TABAS_BathingBenefitDriver.instances[key]
    if inst and inst._startId == benefitData.startId then
        return inst
    end

    TABAS_BathingBenefitDriver.instances[key] = nil

    if benefitData.mode == "BATH" then
        local tfc_Base = TFC_Utils.getTfcBaseOnServer(benefitData.x, benefitData.y, benefitData.z)
        if not tfc_Base then return nil end
        local bathSalt   = tfc_Base:getWaterData("bathSalt")
        local dirtyLevel = tfc_Base:getWaterData("dirtyLevel")

        inst = TABAS_BathingBenefits:new(player, benefitData.mode, bathSalt, dirtyLevel)
        if not inst then return nil end
        inst._tfc_Base = tfc_Base
    else -- SHOWER
        inst = TABAS_BathingBenefits:new(player, benefitData.mode, nil, nil)
        if not inst then return nil end
    end

    inst._startId = benefitData.startId
    TABAS_BathingBenefitDriver.instances[key] = inst
    return inst
end

local function applyForInstance(inst, benefitData)
    if benefitData.mode == "BATH" then
        local tfc_Base
        if not inst._tfc_Base then
            tfc_Base = TFC_Utils.getTfcBaseOnServer(benefitData.x, benefitData.y, benefitData.z)
            if not tfc_Base then return false end
            inst._tfc_Base = tfc_Base
        else
            tfc_Base = inst._tfc_Base
        end
        local waterState = TABAS_BathingUtils.getBathWaterState(tfc_Base)
        if not waterState.canBenefit then return "paused" end

        local ratio = tfc_Base:getRatio() or 0
        inst:apply(waterState.waterTemp, ratio)
        return true
    else -- Shower
        local showerObj = TABAS_Iso.getShowerObjectAt(benefitData.x, benefitData.y, benefitData.z)
        if showerObj then
            local md = showerObj:getModData()
            local canHot = TABAS_Iso.canHot(showerObj)
            local waterTemp = canHot and ((md and md.idealTemperature) or 40.0) or 22.0
            inst:apply(waterTemp, 1)
            return true
        end
        local tfc_Base
        if not inst._tfc_Base then
            tfc_Base = TFC_Utils.getTfcBaseOnServer(benefitData.x, benefitData.y, benefitData.z)
            if not tfc_Base then return false end
            inst._tfc_Base = tfc_Base
        else
            tfc_Base = inst._tfc_Base
        end
        if tfc_Base then
            local waterTemp = tfc_Base:getBathData("temperature") or 40.0
            inst:apply(waterTemp, 1)
            return true
        end
        return false
    end
end

local function pauseBenefitProgress(player, benefitData)
    if benefitData then
        benefitData._lastH = TABAS_GameTimes.getWorldAgeHours()
    end
    TABAS_BathingBenefitDriver.stop(player, false)
end

function TABAS_BathingBenefitDriver.update(player)
    local md = player:getModData()
    if not md then return end

    if not md.tabas_IsBathing then
        TABAS_BathingBenefitDriver.stop(player, false)
        return
    end

    local benefitData = md.tabas_BathingBenefit
    if not benefitData then
        TABAS_BathingBenefitDriver.stop(player, true)
        return
    end

    local bathingActive = TABAS_BathingUtils.hasBathingElapsed(md, TABAS_BathingUtils.getBathingWetDelaySec())
    if not bathingActive then
        TABAS_BathingBenefitDriver.stop(player, false)
        return
    end

    local inst = TABAS_BathingBenefitDriver.getInstance(player, benefitData)
    if not inst then
        pauseBenefitProgress(player, benefitData)
        return
    end

    local applied = applyForInstance(inst, benefitData)
    if applied == "paused" then
        pauseBenefitProgress(player, benefitData)
        return
    end

    if not applied then
        TABAS_BathingBenefitDriver.stop(player, true)
        return
    end
end

local function everyOneMinute()
    if isServer() then
        local players = getOnlinePlayers()
        for i=0, players:size()-1 do
            local player = players:get(i)
            if player and not player:isDead() then
                TABAS_BathingBenefitDriver.update(player)
            end
        end
    else
        for i=0, getNumActivePlayers()-1 do
            local player = getSpecificPlayer(i)
            if player and not player:isDead() then
                TABAS_BathingBenefitDriver.update(player)
            end
        end
    end
end

Events.EveryOneMinute.Add(everyOneMinute)
