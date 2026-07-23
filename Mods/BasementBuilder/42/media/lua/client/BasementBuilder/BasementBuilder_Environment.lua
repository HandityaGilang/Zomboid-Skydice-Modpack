require "BasementBuilder/BasementBuilder_Core"

BasementBuilder_Environment = BasementBuilder_Environment or {}

local bbEnv = BasementBuilder_Environment

local function bbEnvLog(message)
    -- print("[BasementBuilder][Env][Client] " .. tostring(message))
end

local function reduceWetnessValue(value, amount)
    if not value or value <= 0 then
        return value
    end
    return math.max(0, value - amount)
end

function bbEnv.reducePlayerWetness(playerObj)
    if not playerObj or not BasementBuilder.isPlayerInBasement(playerObj) then
        return
    end

    local stats = playerObj:getStats()
    if stats and stats.set and stats.get then
        local wetness = stats:get(CharacterStat.WETNESS)
        stats:set(CharacterStat.WETNESS, math.max(0, wetness - 25))
        bbEnvLog("reduce wetness player=" .. tostring(playerObj:getPlayerNum()) .. " stat " .. tostring(wetness) .. " -> " .. tostring(stats:get(CharacterStat.WETNESS)))
    end

    local bodyDamage = playerObj:getBodyDamage()
    if bodyDamage and bodyDamage.decreaseBodyWetness and stats and stats.get then
        bodyDamage:decreaseBodyWetness(stats:get(CharacterStat.WETNESS) + 25)
    end
    if bodyDamage and bodyDamage.getBodyParts then
        local bodyParts = bodyDamage:getBodyParts()
        for i = 0, bodyParts:size() - 1 do
            local bodyPart = bodyParts:get(i)
            if bodyPart and bodyPart.getWetness and bodyPart.setWetness then
                bodyPart:setWetness(reduceWetnessValue(bodyPart:getWetness(), 12))
            end
        end
    end

    local wornItems = playerObj:getWornItems()
    if wornItems then
        for i = 0, wornItems:size() - 1 do
            local worn = wornItems:get(i)
            local item = worn and worn.getItem and worn:getItem() or nil
            if item and item.getWetness and item.setWetness then
                item:setWetness(reduceWetnessValue(item:getWetness(), 12))
            end
        end
    end
end

function bbEnv.reduceColdEffects(playerObj)
    if not playerObj or not BasementBuilder.isPlayerInBasement(playerObj) then
        return
    end

    local bodyDamage = playerObj:getBodyDamage()
    if not bodyDamage then
        return
    end

    if bodyDamage.getCatchACold and bodyDamage.setCatchACold then
        local before = bodyDamage:getCatchACold()
        bodyDamage:setCatchACold(math.max(0, bodyDamage:getCatchACold() - 0.25))
        bbEnvLog("reduce catchCold player=" .. tostring(playerObj:getPlayerNum()) .. " " .. tostring(before) .. " -> " .. tostring(bodyDamage:getCatchACold()))
    end
    if bodyDamage.setHasACold then
        bodyDamage:setHasACold(false)
    end
    if bodyDamage.getColdStrength and bodyDamage.setColdStrength then
        local before = bodyDamage:getColdStrength()
        bodyDamage:setColdStrength(math.max(0, bodyDamage:getColdStrength() - 2.0))
        bbEnvLog("reduce coldStrength player=" .. tostring(playerObj:getPlayerNum()) .. " " .. tostring(before) .. " -> " .. tostring(bodyDamage:getColdStrength()))
    end
end

function bbEnv.onEveryOneMinute()
    for playerIndex = 0, 3 do
        local playerObj = getSpecificPlayer(playerIndex)
        if playerObj and BasementBuilder.isPlayerInBasement(playerObj) then
            local square = playerObj:getCurrentSquare()
            bbEnvLog("EveryOneMinute basement player=" .. tostring(playerIndex) .. " square=" .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ()))
            bbEnv.reducePlayerWetness(playerObj)
            bbEnv.reduceColdEffects(playerObj)
        end
    end
end

function bbEnv.onPlayerUpdate(playerObj)
    if not playerObj or not BasementBuilder.isPlayerInBasement(playerObj) then
        return
    end

    local modData = playerObj:getModData()
    modData.BBEnvUpdateCounter = (modData.BBEnvUpdateCounter or 0) + 1
    if modData.BBEnvUpdateCounter % 180 == 0 then
        local square = playerObj:getCurrentSquare()
        bbEnvLog("OnPlayerUpdate basement player=" .. tostring(playerObj:getPlayerNum()) .. " square=" .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ()))
    end

    bbEnv.reducePlayerWetness(playerObj)
    bbEnv.reduceColdEffects(playerObj)
end

function bbEnv.applySleepPatch()
    if bbEnv.sleepPatchApplied then
        return
    end
    if not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.onSleepWalkToComplete then
        return
    end

    local originalOnSleepWalkToComplete = ISWorldObjectContextMenu.onSleepWalkToComplete
    ISWorldObjectContextMenu.onSleepWalkToComplete = function(player, bed)
        local playerObj = getSpecificPlayer(player)
        if BasementBuilder.isPlayerInBasement(playerObj) then
            bbEnvLog("sleep patch hit player=" .. tostring(player))
            bbEnv.reducePlayerWetness(playerObj)
        end
        return originalOnSleepWalkToComplete(player, bed)
    end

    bbEnv.sleepPatchApplied = true
    bbEnvLog("sleep patch applied")
end

function bbEnv.applyGeneratorPatch()
    if bbEnv.generatorPatchApplied then
        return
    end
    if not ISGeneratorInfoWindow or not ISGeneratorInfoWindow.getRichText then
        return
    end

    local originalGetRichText = ISGeneratorInfoWindow.getRichText
    ISGeneratorInfoWindow.getRichText = function(object, displayStats)
        local text = originalGetRichText(object, displayStats)
        local square = object and object.getSquare and object:getSquare() or nil
        if not square or not BasementBuilder.isBasementSquare(square) then
            return text
        end

        local toxicText = getText("IGUI_Generator_IsToxic")
        if string.find(text, toxicText, 1, true) then
            text = string.gsub(text, " <LINE> <RED> " .. toxicText, "", 1)
            text = string.gsub(text, " <RED> " .. toxicText, "", 1)
        end
        return text
    end

    bbEnv.generatorPatchApplied = true
    bbEnvLog("generator patch applied")
end

Events.EveryOneMinute.Add(bbEnv.onEveryOneMinute)
Events.OnPlayerUpdate.Add(bbEnv.onPlayerUpdate)
Events.OnGameStart.Add(bbEnv.applySleepPatch)
Events.OnGameStart.Add(bbEnv.applyGeneratorPatch)

bbEnvLog("environment file loaded")
bbEnv.applySleepPatch()
bbEnv.applyGeneratorPatch()
