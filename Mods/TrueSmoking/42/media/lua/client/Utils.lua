require 'TrueSmoking'

TrueSmoking = TrueSmoking or {}

--Can probably remove this func and use vanilla logic here
function TrueSmoking.canAddToPack(item)
    if instanceof(item, 'Drainable') and item:getTags():contains('Packed') then
        local useDelta = item:getUseDelta()
        if useDelta and useDelta < 1 then
            -- print('TRUESMOKING::Checking if can add to pack: ' .. item:getFullType())
            return true
        end
    else
        return true
    end
end

function TrueSmoking.addToPack(items, result, player)
    local usedItems = items:getAllInputItems()
    local pack = nil
    local cig = nil
    for i = 0, usedItems:size() - 1 do
        local item = usedItems:get(i)
        print('TRUESMOKING::Item: ' .. item:getFullType())
        if item and item:getFullType() == 'Base.CigarettePack' then
            pack = usedItems:get(i)
            if pack:getUseDelta() < 1 then
                pack:setUsedDelta(pack:getCurrentUsesFloat() + pack:getUseDelta())
            end
        elseif item and item:getFullType() == 'Base.CigaretteSingle' then
            cig = item
        end
    end

    if cig then
        local data = cig:getModData()
        if data and data.OriginalSmokeLength and data.SmokeLength < data.OriginalSmokeLength then
            if pack then
                if not pack:getModData().Cigs then
                    pack:getModData().Cigs = {}
                end
                local packData = pack:getModData().Cigs
                local cigID = cig:getID()

                packData[cigID] = {
                    OriginalSmokeLength = data.OriginalSmokeLength,
                    SmokeLength = data.SmokeLength,
                }

                print('TRUESMOKING::Inserting cig data back to pack for ID: ' ..
                    cigID .. ' | OriginalSmokeLength: ' .. data.OriginalSmokeLength .. ' | SmokeLength: ' .. data
                    .SmokeLength)
            end
        end
    end
end

function TrueSmoking.takeACigarette(items, result, player)
    local usedItems = items:getAllInputItems()
    local outputItems = items:getAllCreatedItems()
    local hasData = false
    local pack = nil
    for i = 0, usedItems:size() - 1 do
        local item = usedItems:get(i)
        if item and item:getFullType() == 'Base.CigarettePack' then
            print('TRUESMOKING::Found pack: ' .. item:getFullType())
            if item:getUseDelta() > 0 then
                print('TRUESMOKING::Taking a cig from pack: ' .. item:getFullType())
                -- item:setUsedDelta(item:getCurrentUsesFloat() - item:getUseDelta())
                if item:getModData().Cigs then
                    hasData = true
                    pack = item
                    break
                end
            end
        end
    end

    for i = 0, outputItems:size() - 1 do
        local item = outputItems:get(i)
        if item and item:getFullType() == 'Base.CigaretteSingle' then
            print('TRUESMOKING::Hook cig: ' .. item:getFullType())
            if pack and hasData then
                for key, value in pairs(pack:getModData().Cigs) do
                    item:getModData().OriginalSmokeLength = value.OriginalSmokeLength
                    item:getModData().SmokeLength = value.SmokeLength
                    print('TRUESMOKING::Restored cig data from pack for ID: ' ..
                    key ..
                    ' | OriginalSmokeLength: ' .. value.OriginalSmokeLength .. ' | SmokeLength: ' .. value.SmokeLength)
                    pack:getModData().Cigs[key] = nil
                    break
                end
            end
        end
    end
end

function TrueSmoking.getPlayerState(player)
    local PlayerState = tostring(player:getCurrentState())
    local state = string.match(PlayerState, '([^%.]+)@')
    -- print(string.format('Character State: %s',state))
    return state or false
end

function TrueSmoking.isInList(str, list)
    if str == "" then
        return false
    end
    local listString = table.concat(list, ",")
    return string.find(listString, str) ~= nil
end

function TrueSmoking.deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = TrueSmoking.deepCopy(value) -- Recursively copy nested tables
        else
            copy[key] = value                       -- Copy primitive values directly
        end
    end
    return copy
end

function TrueSmoking.addOnUseItem(player)
    local trueSmoking = TrueSmoking:getPlayerReference(player)
    local type = trueSmoking.Smokable.fullType
    local item = trueSmoking.Smokable.replaceOnUse
    local base = type:match("^[^.]+")
    if base then
        local str = base .. '.' .. item
        if item and item ~= '' then
            print('TRUESMOKING::add item: ' .. str)
            player:getInventory():AddItem(str)
            trueSmoking.Smokable.replaceOnUse = ''
        end
    end
end

function TrueSmoking.getGameSpeedMultiplier()
    local speed = getGameSpeed()
    -- Game speed maps: 1=1x, 2=5x, 3=20x, 4=40x
    if speed == 1 then
        return 1
    elseif speed == 2 then
        return 5
    elseif speed == 3 then
        return 20
    elseif speed == 4 then
        return 40
    else
        return 1 -- Default fallback
    end
end

-- OnEat for applying item stats
function TrueSmoking.OnEat_ItemStats(smokable)
    local percent = smokable.puffPercent
    local character = smokable.player
    local body = character:getBodyDamage()
    local stats = character:getStats()

    local function adjustStat(stat, value, name, add)
        local name = name or 'nil'
        local newStat = stat - math.abs(value)
        -- print(string.format("Name: %s | Stat: %s | Value: %s | New Value: %s", name, stat, value, newStat))
        if newStat < 0 then
            newStat = 0
        end

        if add then newStat = stat + value end

        return newStat
    end

    local temp --Store temp values for calculations

    --If smokable has boredom or unhappyness distribute them (these are applied in vanilla outside of OnEat, but we 0'd them earlier.)
    if smokable.boredom ~= 0 then
        temp = smokable.originalBoredom * percent
        body:setBoredomLevel(adjustStat(body:getBoredomLevel(), temp - ZomboidGlobals.BoredomIncrease, 'boredom'))
        smokable.boredom = smokable.boredom - temp
        -- print(string.format("Smokable boredom: %s | temp: %s", smokable.boredom, temp))
        if smokable.boredom > 0 then
            smokable.boredom = 0
        end
    end

    --Handles hunger
    if smokable.hunger ~= 0 then
        temp = smokable.originalHunger * percent
        stats:setHunger(adjustStat(stats:getHunger(), temp, 'hunger', true))
        smokable.hunger = smokable.hunger - temp
        if smokable.hunger < 0 then
            smokable.hunger = 0
        end
    end

    --Handles thirst
    if smokable.thirst ~= 0 then
        temp = smokable.originalThirst * percent
        stats:setThirst(adjustStat(stats:getThirst(), temp, 'thirst', true))
        smokable.thirst = smokable.thirst - temp
        if smokable.thirst < 0 then
            smokable.thirst = 0
        end
    end

    --Handles pain
    if smokable.pain ~= 0 then
        temp = smokable.originalPain * percent
        stats:setPain(adjustStat(stats:getPain(), temp, 'pain'))
        smokable.pain = smokable.pain - temp
        if smokable.pain < 0 then
            smokable.pain = 0
        end
    end

    --Handles endurance
    if smokable.endurance ~= 0 then
        local add = false;
        if smokable.endurance > 0 then add = true end
        temp = smokable.originalEndurance * percent
        stats:setEndurance(adjustStat(stats:getEndurance(), temp, 'endurance'))
        smokable.endurance = smokable.endurance - temp
        if add and smokable.endurance < 0 then
            smokable.endurance = 0
        elseif not add and smokable.endurance > 0 then
            smokable.endurance = 0
        end
    end

    --Handles endurance
    if smokable.fatigue ~= 0 then
        local add = false;
        if smokable.fatigue > 0 then add = true end
        temp = smokable.originalFatigue * percent
        stats:setFatigue(adjustStat(stats:getFatigue(), temp, 'fatigue', add))
        smokable.fatigue = smokable.fatigue - temp
        if add and smokable.fatigue < 0 then
            smokable.fatigue = 0
        elseif not add and smokable.fatigue > 0 then
            smokable.fatigue = 0
        end
    end

    --Handles reduceFoodSickness
    if smokable.reduceFoodSick ~= 0 then
        temp = smokable.originalReduceFoodSick * percent
        body:setFoodSicknessLevel(math.min(body:getFoodSicknessLevel() - temp, 100))
        smokable.reduceFoodSick = smokable.reduceFoodSick - temp
        if smokable.reduceFoodSick < 0 then
            smokable.reduceFoodSick = 0
        end
    end
end

--OnEat method for distributing Tobacco effects from Vanilla
function TrueSmoking.OnEat_Tobacco(smokable)
    local percent = smokable.puffPercent
    local character = smokable.player
    local data = character:getModData().nicotineSystem
    -- if data and TrueSmoking.Options.UseNicotineSystem then
    --     percent = percent * data.toleranceFactor
    -- end
    local body = character:getBodyDamage()
    local stats = character:getStats()

    local effectMultiplier = smokable.effectMultiplier

    local function adjustStat(stat, value, name, add)
        local name = name or 'nil'
        local newStat = stat - math.abs(value)
        if newStat < 0 then
            newStat = 0
        end

        if add then newStat = stat + value end

        return newStat
    end

    local temp --Store temp values for calculations

    --Mimic vanilla logic for smoker which essentially 0's these stats
    if character:HasTrait("Smoker") then
        temp = 100 * percent * effectMultiplier
        body:setUnhappynessLevel(adjustStat(body:getUnhappynessLevel(), temp, 'unhappy'))

        temp = 1 * percent * effectMultiplier
        stats:setStress(adjustStat(stats:getStress() - stats:getStressFromCigarettes(), temp, 'stress'))

        temp = 0.51 * percent * effectMultiplier
        stats:setStressFromCigarettes(adjustStat(stats:getStressFromCigarettes(), temp, 'cigs'))

        temp = 10 * percent * effectMultiplier
        character:setTimeSinceLastSmoke(character:getTimeSinceLastSmoke() - temp)
    else --distribute stats for non smoker (stress and sickness)
        temp = smokable.originalStress * percent
        stats:setStress(adjustStat(stats:getStress(), temp * effectMultiplier))
        smokable.stress = smokable.stress - temp

        --Set these to 0 anyways for safety.
        stats:setStressFromCigarettes(0)
        character:setTimeSinceLastSmoke(0)

        if smokable.stress > 0 then
            smokable.stress = 0
        end

        if smokable.foodSick ~= 0 then
            temp = smokable.originalFoodSick * percent
            body:setFoodSicknessLevel(math.min(body:getFoodSicknessLevel() + temp * effectMultiplier, 100))
            smokable.foodSick = smokable.foodSick - temp
            if smokable.foodSick < 0 then
                smokable.foodSick = 0
            end
        end

        if smokable.unhappyness ~= 0 then
            temp = smokable.originalUnhappyness * percent
            body:setUnhappynessLevel(adjustStat(body:getUnhappynessLevel(), temp * effectMultiplier, 'unhappy'))
            smokable.unhappyness = smokable.unhappyness - temp
            if smokable.unhappyness > 0 then
                smokable.unhappyness = 0
            end
        end
    end

    OnEat_Tobacco = TrueSmoking.OnEat_Tobacco
end
