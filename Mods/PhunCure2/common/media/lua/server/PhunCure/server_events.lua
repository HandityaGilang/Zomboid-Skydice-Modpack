if isClient() then
    return
end
require "PhunCure/core"
local Commands = require "PhunCure/server_commands"
local Core = PhunCure
local getTimestamp = getTimestamp

local PZ = PhunZones

-- Determine if sprinter cure scanning is needed (auto-detected, no setting required)
local enableSprinterCure = false
local pendingSprinterIds = {}
local pendingSprinterCount = 0

if PhunSprinters then
    local defRate = Core.getOption("DefDropRate", 1)
    local sprinterRate = Core.getOption("DefSprinterDropRate", 1)
    if defRate ~= sprinterRate then
        enableSprinterCure = true
    elseif PZ and PZ.data and PZ.data.lookup then
        for _, zone in pairs(PZ.data.lookup) do
            if zone.cureDropRate ~= zone.dropRateSprinters then
                enableSprinterCure = true
                break
            end
        end
    end
    if enableSprinterCure then
        Core.debugLn("Sprinter cure scanning enabled")
    end
end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end

    if enableSprinterCure and module == "PhunSprinters" and command == "isSprinter" then
        for zedId, isSprinter in pairs(arguments) do
            if isSprinter and not pendingSprinterIds[tostring(zedId)] then
                pendingSprinterIds[tostring(zedId)] = true
                pendingSprinterCount = pendingSprinterCount + 1
            end
        end
    end
end)

local function makeCarrier(zed)
    zed:dressInPersistentOutfit("HazardSuit")
    zed:resetModelNextFrame()
    zed:resetModel()
    Core.debugLn("Carrier zed created")
end

local tests = {}
local counts = 0

-- When a zed spawns, roll the dice. Winners get dressed in hazmat.
Events.OnZombieCreate.Add(function(zed)

    if not zed then
        return
    end

    local data = Core.getZData(zed)

    if tests[data.id] then
        return -- Already tested this zed, skip
    end

    tests[data.id] = true

    if tostring(zed:getOutfitName()) == "HazardSuit" then
        -- already a carrier
        if not data.tested then
            data.tested = true
            counts = counts + 1
        end
        return
    end

    if data.tested then
        return
    else

        data.tested = true
    end

    local location = PZ and PZ.getLocation and PZ.getLocation(zed) or nil
    local rate = math.floor((tonumber(location and location.cureDropRate or Core.getOption("DefDropRate", 1)) or 0) *
                                100)

    if rate <= 0 then
        Core.debugLn("Zed " .. tostring(data.id) .. " has 0% carrier chance, skipping")
        return
    end

    local roll = ZombRand(10000) + 1
    if roll <= rate then
        Core.debugLn("Zed " .. tostring(data.id) .. " rolled " .. tostring(roll) .. "/" .. tostring(rate) ..
                         " and is a carrier")
        counts = counts + 1
        makeCarrier(zed)
    else
        Core.debugLn("Zed " .. tostring(data.id) .. " rolled " .. tostring(roll) .. "/" .. tostring(rate) ..
                         " and is not a carrier")
    end
end)

Events.EveryDays.Add(function()
    tests = {}
    counts = 0
    Core.debugLn("Resetting carrier debug counts")
end)

Events.EveryTenMinutes.Add(function()

    if not Core.settings.Debug then
        return
    end

    local total = 0
    for _ in pairs(tests) do
        total = total + 1
    end

    Core.debugLn("Total zeds tested for cure carrier status: " .. tostring(total) .. ", carriers created: " ..
                     tostring(counts) .. " = " .. (total > 0 and string.format("%.2f", counts / total * 100) or "0") ..
                     "%")
end)

local nextSprinterCheck = getTimestamp()
Events.OnTick.Add(function()
    if not enableSprinterCure then
        return
    end
    if pendingSprinterCount == 0 then
        return
    end
    if getTimestamp() < nextSprinterCheck then
        return
    end
    nextSprinterCheck = getTimestamp() + 2

    local cell = getCell()
    if not cell then
        return
    end

    local location = PZ and PZ.getLocation or nil
    local rate = math.floor((tonumber(Core.getOption("DefSprinterDropRate", 1)) or 0) * 100)
    if rate <= 0 then
        pendingSprinterIds = {}
        pendingSprinterCount = 0
        return
    end

    local zombies = cell:getZombieList()
    for i = 0, zombies:size() - 1 do
        local zed = zombies:get(i)
        local id = Core.getZId(zed)
        if id and pendingSprinterIds[id] then
            pendingSprinterIds[id] = nil
            pendingSprinterCount = pendingSprinterCount - 1
            -- Skip if already a carrier
            if tostring(zed:getOutfitName()) ~= "HazardSuit" then
                local data = Core.getZData(zed)
                if not data.testedSprinter then
                    data.testedSprinter = true
                    local loc = location and location(zed) or nil
                    local r = math.floor((tonumber(loc and loc.dropRateSprinters or
                                                       Core.getOption("DefSprinterDropRate", 1)) or 0) * 100)
                    if r > 0 and ZombRand(10000) + 1 <= r then
                        makeCarrier(zed)
                    end
                end
            end
            if pendingSprinterCount == 0 then
                break
            end
        end
    end
end)

-- When a hazmat zed dies, add the cure to its inventory (loot is generated at death)
Events.OnZombieDead.Add(function(zed)
    if not zed or tostring(zed:getOutfitName()) ~= "HazardSuit" then
        return
    end

    local expiredChance = Core.getOption("ExpiredChance", 0)
    if expiredChance > 0 and ZombRand(1, 101) <= expiredChance then
        Core.debugLn("Carrier zed dropped expired cure")
        local item = zed:getInventory():AddItem("PhunCure.Cure")
        item:setAge(item:getOffAgeMax() + ZombRand(1, 10))
    else
        Core.debugLn("Carrier zed dropped fresh cure")
        zed:getInventory():AddItem("PhunCure.Cure")
    end
end)
