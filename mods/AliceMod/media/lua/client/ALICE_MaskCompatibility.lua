local ALICE_GAS_MASKS = {
    ["ALICE.M40GasMaskStraps"] = true,
    ["ALICE.M40GasMaskNoStraps"] = true,
}

local workingMasksEnabled = false
local previousSicknessByPlayer = {}

local function isModActive(modId)
    return getActivatedMods() and getActivatedMods():contains(modId)
end

local function registerSusceptibleMasks()
    if not isModActive("Susceptible") then
        return
    end

    if not SusceptibleMaskItems then
        pcall(require, "Susceptible/SusceptibleMaskData")
    end

    if not SusceptibleMaskItems or not SusceptibleRepairTypes then
        return
    end

    local maskData = { durability = 400, repairType = SusceptibleRepairTypes.FILTER }
    SusceptibleMaskItems["ALICE.M40GasMaskStraps"] = maskData
    SusceptibleMaskItems["ALICE.M40GasMaskNoStraps"] = maskData
    SusceptibleMaskItems.M40GasMaskStraps = maskData
    SusceptibleMaskItems.M40GasMaskNoStraps = maskData
end

local function getWornAliceGasMask(player)
    local wornItems = player:getWornItems()
    local bodyLocations = { "Mask", "MaskEyes", "MaskFull", "FullHat", "FullSuitHead" }

    for i = 1, #bodyLocations do
        local item = wornItems:getItem(bodyLocations[i])
        if item and ALICE_GAS_MASKS[item:getFullType()] then
            return item
        end
    end

    return nil
end

local function getMaskEfficiency(maskItem)
    local conditionMax = maskItem:getConditionMax()
    if conditionMax <= 0 then
        return 0
    end

    return maskItem:getCondition() / conditionMax
end

local function applyWorkingMasksCompatibility(player)
    if not workingMasksEnabled then
        return
    end

    local playerNum = player:getPlayerNum()
    local bodyDamage = player:getBodyDamage()
    local currentSickness = bodyDamage:getFoodSicknessLevel()
    local previousSickness = previousSicknessByPlayer[playerNum]

    if not previousSickness then
        previousSicknessByPlayer[playerNum] = currentSickness
        return
    end

    local maskItem = getWornAliceGasMask(player)
    local maskEfficiency = maskItem and getMaskEfficiency(maskItem) or 0

    if maskEfficiency <= 0 or currentSickness <= 0 then
        previousSicknessByPlayer[playerNum] = currentSickness
        return
    end

    local deltaSicknessLevel = currentSickness - previousSickness
    local newSickness = currentSickness

    if deltaSicknessLevel > 0 then
        local gameTimeMultiplier = GameTime.getInstance():getMultiplier()
        local poisonLevel = bodyDamage:getPoisonLevel()
        local sicknessFromCorpses = deltaSicknessLevel

        if poisonLevel > 0.0 then
            sicknessFromCorpses = deltaSicknessLevel - ((bodyDamage:getInfectionGrowthRate() * (2 + Math.round(poisonLevel / 10.0))) * gameTimeMultiplier)
        end

        if sicknessFromCorpses > 0 then
            local sicknessFromCorpseRate = BodyDamage.getSicknessFromCorpsesRate(6)
            local estimatedCorpses = sicknessFromCorpses / sicknessFromCorpseRate / gameTimeMultiplier
            local cappedCorpses = Math.min(Math.ceil(estimatedCorpses), 20)
            local sicknessFromCorpsesAdjusted = cappedCorpses * sicknessFromCorpseRate * gameTimeMultiplier

            newSickness = currentSickness - (sicknessFromCorpsesAdjusted * maskEfficiency)
            if newSickness < 0 then
                newSickness = 0
            end

            bodyDamage:setFoodSicknessLevel(newSickness)
        end
    end

    previousSicknessByPlayer[playerNum] = newSickness
end

local function initializeCompatibility()
    workingMasksEnabled = isModActive("WorkingMasks")
    registerSusceptibleMasks()
end

Events.OnGameStart.Add(initializeCompatibility)
Events.OnCreatePlayer.Add(registerSusceptibleMasks)
Events.OnPlayerUpdate.Add(applyWorkingMasksCompatibility)
