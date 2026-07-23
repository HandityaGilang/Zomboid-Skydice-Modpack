

LSAmbtMng = LSAmbtMng or {}

LSAmbtMng.getAmbtData = function(charData, ambtName)
    local data = charData and charData.Ambitions
    return data and data[ambtName]
end

LSAmbtMng.hasActiveCompleted = function(character, ambtName)
    local ambtData = LSAmbtMng.getAmbtData(character:getModData(), ambtName)
    return ambtData and not ambtData.disable and ambtData.completed and ambtData.isActive
end

LSAmbtMng.hasActive = function(character, ambtName)
    local ambtData = LSAmbtMng.getAmbtData(character:getModData(), ambtName)
    return ambtData and not ambtData.disable and (ambtData.isPassive or ambtData.isActive)
end

LSAmbtMng.hasCompleted = function(character, ambtName)
    local ambtData = LSAmbtMng.getAmbtData(character:getModData(), ambtName)
    return ambtData and not ambtData.disable and ambtData.completed
end

LSAmbtMng.hasAmbition = function(character, ambtName)
    local ambtData = LSAmbtMng.getAmbtData(character:getModData(), ambtName)
    return ambtData and not ambtData.disable and not ambtData.isHidden
end

LSAmbtMng.syncProgress = function(player, ambitionId, goalIndex, delta)
    if not isClient() or not player then
        return
    end
    if not LifestyleSecure.ClientSystems then
        pcall(require, "LifestyleCore/LSK_SystemsClient")
    end
    if LifestyleSecure.ClientSystems then
        LifestyleSecure.ClientSystems.ambitionProgress(player, ambitionId, goalIndex, delta or 1)
    end
end