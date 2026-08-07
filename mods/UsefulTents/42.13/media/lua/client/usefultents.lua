local lastTentState = nil
local dryingRates = {
    small = 0.001,
    medium = 0.007,
    medium_big = 0.010,
    big = 0.013
}

local currentTentType = nil
local tentTypeCache = {}

local function getTentType(spriteName)
    if not spriteName then return nil end
    
    if tentTypeCache[spriteName] then
        return tentTypeCache[spriteName]
    end

    local tentType
    if string.match(spriteName, "^camping_03_2[4-7]$") or
        string.match(spriteName, "^camping_03_4[0-7]$") then
        tentType = "small"
    elseif string.match(spriteName, "^camping_03_[0-9]$") or 
            string.match(spriteName, "^camping_03_1[0-5]$") or 
            string.match(spriteName, "^camping_03_3[2-9]$") or 
            string.match(spriteName, "^camping_01_[0-3]$") then
        tentType = "medium"
    elseif string.match(spriteName, "^camping_04_[0-9]$") or 
           string.match(spriteName, "^camping_04_[0-9][0-9]$") or 
           string.match(spriteName, "^camping_04_1[0-1][0-9]$") or 
           string.match(spriteName, "^camping_04_12[0-7]$") then
        tentType = "medium_big"
    elseif string.match(spriteName, "^camping_01_[4-6]$") then
        tentType = "campfire"
    end

    tentTypeCache[spriteName] = tentType
    return tentType
end

local function isNearTent(isoPlayer)
    if not isoPlayer then return false end
    local sq = isoPlayer:getSquare()
    if not sq then return false end

    local cell = getCell()
    local tentFound = false

    for dx = -1, 1 do
        for dy = -1, 1 do
            local tile = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
            if tile then
                local objects = tile:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj then
                        local sprite = obj:getSprite()
                        if sprite then
                            local spriteName = sprite:getName()
                            local tentType = getTentType(spriteName)
                            if tentType == "campfire" then
                                -- Skip campfires
                            elseif tentType then
                                currentTentType = tentType
                                tentFound = true
                                break
                            end
                        end
                    end
                end
                if tentFound then break end
            end
        end
        if tentFound then break end
    end

    if not tentFound then
        currentTentType = nil
    end
    return tentFound
end

local function checkTentState(isoPlayer)
    if not isoPlayer then return end
    local isUnderTent = isNearTent(isoPlayer)

    if lastTentState ~= isUnderTent then
        lastTentState = isUnderTent
        isoPlayer:getModData().UnderTent = isUnderTent
    end
end

local function onPlayerSleep(isoPlayer)
    if isoPlayer then
        checkTentState(isoPlayer)
    end
end

local function updateWetness(isoPlayer, speedMultiplier, isSleeping)
    if not isoPlayer then 
        return 
    end

    local modData = isoPlayer:getModData()
    if not modData or not modData.UnderTent then 
        return 
    end

    local stats = isoPlayer:getStats()
    local currentWetness = stats:get(CharacterStat.WETNESS)

    local adjustedDryingRate = currentTentType and dryingRates[currentTentType]
    
    if currentWetness > 0 then
        local newWetness = currentWetness - (adjustedDryingRate * speedMultiplier)
        stats:set(CharacterStat.WETNESS, newWetness)
    end


    -- Handle clothing wetness
    local wornItems = isoPlayer:getWornItems()
    if wornItems and wornItems:size() > 0 then
        for i = 0, wornItems:size() - 1 do
            local wornItem = wornItems:get(i)
            if wornItem then
                local item = wornItem:getItem()
                if item and item.getWetness and item.setWetness then
                    local itemWetness = item:getWetness() or 0

                    if itemWetness > 0 then
                        local newItemWetness = itemWetness - (adjustedDryingRate * speedMultiplier)
                        item:setWetness(newItemWetness)
                    end
                end
            end
        end
    end
end

-- local function reduce_insulation(isoPlayer)
    -- if not isoPlayer then return end
    -- local modData = isoPlayer:getModData()

    -- print("insulation: ", isoPlayer:getBodyDamage())
    
    -- if modData and modData.UnderTent then
    --     local moodles = isoPlayer:getMoodles();

    --     if moodles then
    --         local currentPanic = moodles:getMoodleLevel(MoodleType.PANIC);
    --         if currentPanic and currentPanic > 0 then
    --             if isSleeping then
    --                 -- Instant panic relief when sleeping in tent
    --                 stats:setPanic(0)
    --             else
    --                 -- Regular panic reduction when awake
    --                 local adjustedPanicReduction = panicReductionRate * speedMultiplier
    --                 local newPanic = math.max(0, currentPanic - adjustedPanicReduction)
    --                 stats:setPanic(newPanic)
    --             end
    --         end
    --     end
    -- end
-- end

local function onPlayerUpdate(isoPlayer)
    if not isoPlayer then return end

    local speedMultipliers = {
        [1] = 1,
        [2] = 10,
        [3] = 30,
        [4] = 65
    }

    local gameSpeed = getGameSpeed()
    local speedMultiplier = speedMultipliers[gameSpeed] or 1

    checkTentState(isoPlayer)
    
    local isSleeping = isoPlayer:isAsleep()
    if isSleeping then
        local modData = isoPlayer:getModData()
        if modData and modData.UnderTent then
            updateWetness(isoPlayer, speedMultiplier, true)
            -- reduce_insulation(isoPlayer, speedMultiplier, true)
        end
    else
        updateWetness(isoPlayer, speedMultiplier, false)
        -- reduce_insulation(isoPlayer)
    end
end

local function initCampInTheRain()
    if Events then
        if Events.OnPlayerMove then
            Events.OnPlayerMove.Add(checkTentState)
        end
        
        if Events.OnPlayerUpdate then
            Events.OnPlayerUpdate.Add(onPlayerUpdate)
        end
        
        if Events.OnPlayerSleep then
            Events.OnPlayerSleep.Add(onPlayerSleep)
        end
    end
end

initCampInTheRain()