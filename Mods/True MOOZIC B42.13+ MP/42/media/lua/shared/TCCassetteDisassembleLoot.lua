-- Shared disassembly loot logic for True MooZic
-- Used by both server and client (singleplayer) for consistent results

TCCassetteDisassembleLoot = TCCassetteDisassembleLoot or {}

local function findPerkByNameFragment(fragment)
    if not Perks or type(Perks) ~= "table" then return nil end
    if Perks[fragment] then return Perks[fragment] end
    local target = tostring(fragment):lower()
    for k, v in pairs(Perks) do
        if type(k) == "string" and k:lower():find(target, 1, true) then
            return v
        end
    end
    return nil
end

local function getPerkLevelSafe(player, perk)
    if not player or not perk then return 0 end
    if not player.getPerkLevel then return 0 end
    return player:getPerkLevel(perk) or 0
end

local function existsItem(fullType)
    return fullType and getScriptManager():FindItem(fullType) ~= nil
end

local function addItemSafe(inventory, fullType, count)
    if not inventory or not fullType or not count or count <= 0 then return end
    if not existsItem(fullType) then return end
    for i = 1, count do
        local item = instanceItem(fullType)
        if item then
            inventory:AddItem(item)
            if sendAddItemToContainer then
                sendAddItemToContainer(inventory, item)
            end
        end
    end
end

local function chooseFirstExisting(list)
    if not list then return nil end
    for _, fullType in ipairs(list) do
        if existsItem(fullType) then
            return fullType
        end
    end
    return nil
end

local function rollRange(minCount, maxCount)
    if not maxCount or maxCount < 0 then return 0 end
    local minVal = minCount or 0
    if maxCount < minVal then
        minVal, maxCount = maxCount, minVal
    end
    return minVal + ZombRand(maxCount - minVal + 1)
end

local function rollChance(chance)
    if chance <= 0 then return false end
    if chance >= 1 then return true end
    return ZombRand(100) < math.floor(chance * 100 + 0.5)
end

local function rollSkillCount(maxCount, skillLevel, baseChance, bonusPerLevel)
    local count = 0
    if not maxCount or maxCount <= 0 then return 0 end
    local chance = (baseChance or 0) + (skillLevel or 0) * (bonusPerLevel or 0)
    if chance < 0 then chance = 0 end
    if chance > 0.95 then chance = 0.95 end
    for i = 1, maxCount do
        if rollChance(chance) then
            count = count + 1
        end
    end
    return count
end

local function getColorKeyFromType(fullTypeOrType)
    if not fullTypeOrType then return nil end
    local s = tostring(fullTypeOrType):lower()
    if s:find("red", 1, true) then return "red" end
    if s:find("blue", 1, true) then return "blue" end
    if s:find("green", 1, true) then return "green" end
    if s:find("pink", 1, true) then return "pink" end
    if s:find("purple", 1, true) then return "purple" end
    if s:find("yellow", 1, true) then return "yellow" end
    if s:find("orange", 1, true) then return "orange" end
    if s:find("white", 1, true) then return "white" end
    return nil
end

local function getColoredBulbForDevice(fullTypeOrType)
    local colorKey = getColorKeyFromType(fullTypeOrType)
    if not colorKey then return nil end

    local candidates = nil
    if colorKey == "red" then
        candidates = { "Base.LightBulbRed", "Base.RedLightBulb" }
    elseif colorKey == "blue" then
        candidates = { "Base.LightBulbBlue", "Base.BlueLightBulb" }
    elseif colorKey == "green" then
        candidates = { "Base.LightBulbGreen", "Base.GreenLightBulb" }
    elseif colorKey == "pink" then
        candidates = { "Base.LightBulbPink", "Base.PinkLightBulb", "Base.LightBulbMagenta" }
    elseif colorKey == "purple" then
        candidates = { "Base.LightBulbPurple", "Base.PurpleLightBulb" }
    elseif colorKey == "yellow" then
        candidates = { "Base.LightBulbYellow", "Base.YellowLightBulb" }
    elseif colorKey == "orange" then
        candidates = { "Base.LightBulbOrange", "Base.OrangeLightBulb" }
    elseif colorKey == "white" then
        candidates = { "Base.LightBulbWhite", "Base.WhiteLightBulb" }
    end

    return chooseFirstExisting(candidates)
end

local function getDeviceItemType(item)
    if not item or not item.getType then return nil end
    return item:getType()
end

local function isWalkman(itemType)
    return itemType and itemType:find("TCWalkman", 1, true) ~= nil
end

local function isBoombox(itemType)
    return itemType and itemType:find("TCBoombox", 1, true) ~= nil
end

local function isVinylPlayer(itemType)
    return itemType and itemType:find("TCVinylplayer", 1, true) ~= nil
end

local function isCassetteMedia(itemType)
    if not itemType then return false end
    if itemType:find("Cassette", 1, true) then return true end
    return false
end

local function getMediaItemFromDevice(item)
    if not item or not item.getModData then return nil end
    local md = item:getModData()
    if not md or not md.tcmusic then return nil end
    return md.tcmusic.mediaItem
end

local function resolveMediaFullType(mediaItem)
    if not mediaItem or type(mediaItem) ~= "string" then return nil end
    if mediaItem:find("%.", 1, true) then
        return existsItem(mediaItem) and mediaItem or nil
    end
    local withTsar = "Tsarcraft." .. mediaItem
    if existsItem(withTsar) then return withTsar end
    local withBase = "Base." .. mediaItem
    if existsItem(withBase) then return withBase end

    local allItems = getAllItems()
    if allItems then
        for i = 0, allItems:size() - 1 do
            local item = allItems:get(i)
            if item and item.getName and item:getName() == mediaItem then
                local full = item.getFullName and item:getFullName() or nil
                if existsItem(full) then
                    return full
                end
            end
        end
    end

    return nil
end

function TCCassetteDisassembleLoot.DeviceHasMedia(item)
    return getMediaItemFromDevice(item) ~= nil
end

function TCCassetteDisassembleLoot.ReturnMediaToInventory(player, item)
    if not player or not item then return false end
    local mediaItem = getMediaItemFromDevice(item)
    if not mediaItem then return false end

    local fullType = resolveMediaFullType(mediaItem)
    if not fullType then return false end

    local inventory = player:getInventory()
    if not inventory then return false end
    local mediaItem = instanceItem(fullType)
    if mediaItem then
        inventory:AddItem(mediaItem)
        if sendAddItemToContainer then
            sendAddItemToContainer(inventory, mediaItem)
        end
    end

    local md = item:getModData()
    if md and md.tcmusic then
        md.tcmusic.mediaItem = nil
    end
    return true
end

function TCCassetteDisassembleLoot.ApplyDisassemblyLoot(player, item)
    if not player or not item then return end
    local inventory = player:getInventory()
    if not inventory then return end

    local itemType = getDeviceItemType(item)
    local fullType = item.getFullType and item:getFullType() or itemType

    local electricalPerk = Perks and Perks.Electrical or findPerkByNameFragment("electr")
    local metalPerk = Perks and (Perks.MetalWelding or Perks.Metalworking) or findPerkByNameFragment("metal")
    local electricalSkill = getPerkLevelSafe(player, electricalPerk)
    local metalSkill = getPerkLevelSafe(player, metalPerk)

    -- Skill-affected roll tuning (kept consistent across items)
    local baseChance = 0.25
    local bonusPerLevel = 0.05

    -- Media items (cassettes only; vinyl records are not disassemblable)
    if isCassetteMedia(itemType) then
        addItemSafe(inventory, "Base.ElectronicsScrap", rollRange(1, 2))
        addItemSafe(inventory, "Base.Scotchtape", rollRange(0, 1))
        addItemSafe(inventory, "Base.ElectricWire", rollSkillCount(1, electricalSkill, 0.20, bonusPerLevel))
        return
    end

    -- Walkman
    if isWalkman(itemType) then
        addItemSafe(inventory, "Base.AluminumFoil", rollRange(0, 4))
        addItemSafe(inventory, "Base.amplifier", rollSkillCount(1, electricalSkill, baseChance, bonusPerLevel))
        addItemSafe(inventory, "Base.ElectricWire", rollRange(0, 4))
        addItemSafe(inventory, "Base.ElectronicsScrap", rollRange(1, 5))

        local coloredBulb = getColoredBulbForDevice(fullType or itemType)
        if coloredBulb then
            addItemSafe(inventory, coloredBulb, rollSkillCount(1, electricalSkill, 0.20, bonusPerLevel))
        end
        addItemSafe(inventory, "Base.LightBulb", rollSkillCount(1, electricalSkill, 0.25, bonusPerLevel))

        -- If device has headphones or battery installed, return them
        local deviceData = item.getDeviceData and item:getDeviceData() or nil
        if deviceData then
            if deviceData.getHeadphoneType and deviceData:getHeadphoneType() >= 0 and deviceData.getHeadphones then
                deviceData:getHeadphones(inventory)
            end
            if deviceData.getIsBatteryPowered and deviceData:getIsBatteryPowered() and deviceData.getHasBattery and deviceData:getHasBattery() and deviceData.getBattery then
                deviceData:getBattery(inventory)
            end
        end
        return
    end

    -- Boombox
    if isBoombox(itemType) then
        addItemSafe(inventory, "Base.AluminumFoil", rollRange(0, 4))
        addItemSafe(inventory, "Base.amplifier", rollSkillCount(2, electricalSkill, baseChance, bonusPerLevel))
        addItemSafe(inventory, "Base.ElectronicsScrap", rollRange(1, 5))
        local wireCount = rollRange(0, 4)
        addItemSafe(inventory, "Base.ElectricWire", wireCount)
        addItemSafe(inventory, "Base.Wire", wireCount)

        local coloredBulb = getColoredBulbForDevice(fullType or itemType)
        if coloredBulb then
            addItemSafe(inventory, coloredBulb, rollSkillCount(1, electricalSkill, 0.20, bonusPerLevel))
        end
        addItemSafe(inventory, "Base.LightBulb", rollSkillCount(1, electricalSkill, 0.25, bonusPerLevel))

        local radioTx = chooseFirstExisting({ "Base.RadioTransmitter" })
        addItemSafe(inventory, radioTx, rollSkillCount(1, electricalSkill, 0.20, bonusPerLevel))

        local deviceData = item.getDeviceData and item:getDeviceData() or nil
        if deviceData then
            if deviceData.getHeadphoneType and deviceData:getHeadphoneType() >= 0 and deviceData.getHeadphones then
                deviceData:getHeadphones(inventory)
            end
            if deviceData.getIsBatteryPowered and deviceData:getIsBatteryPowered() and deviceData.getHasBattery and deviceData:getHasBattery() and deviceData.getBattery then
                deviceData:getBattery(inventory)
            end
        end
        return
    end

    -- Vinyl player
    if isVinylPlayer(itemType) then
        addItemSafe(inventory, "Base.ScrapWood", rollRange(0, 2))
        addItemSafe(inventory, "Base.BrokenGlass", rollRange(0, 2))
        local smallSheet = chooseFirstExisting({ "Base.SmallSheetMetal", "Base.SheetMetalSmall" })
        addItemSafe(inventory, smallSheet, rollSkillCount(2, metalSkill, 0.25, 0.05))

        addItemSafe(inventory, "Base.ElectronicsScrap", rollRange(1, 4))
        local wireCount = rollRange(0, 3)
        addItemSafe(inventory, "Base.ElectricWire", wireCount)
        addItemSafe(inventory, "Base.Wire", wireCount)
        addItemSafe(inventory, "Base.amplifier", rollSkillCount(2, electricalSkill, baseChance, bonusPerLevel))

        local radioRx = chooseFirstExisting({ "Base.RadioReceiver" })
        addItemSafe(inventory, radioRx, rollSkillCount(1, electricalSkill, 0.20, bonusPerLevel))

        local needle = chooseFirstExisting({ "Base.Needle" })
        addItemSafe(inventory, needle, rollRange(0, 1))
        return
    end
end

function TCCassetteDisassembleLoot.ShouldFailDisassembly(player)
    if not TCCassetteDisassembleDefinitions then
        pcall(function() require "TCCassetteDisassembleDefinitions" end)
    end
    if not TCCassetteDisassembleDefinitions then return false end

    local electricalPerk = Perks and Perks.Electrical or findPerkByNameFragment("electr")
    local electricalSkill = getPerkLevelSafe(player, electricalPerk)

    local baseChance = TCCassetteDisassembleDefinitions.Failure.BaseChance or 0.60
    local reduction = TCCassetteDisassembleDefinitions.Failure.SkillReduction or 0.10
    local minChance = TCCassetteDisassembleDefinitions.Failure.MinChance or 0.0

    local failureChance = baseChance - (electricalSkill * reduction)
    if failureChance < minChance then failureChance = minChance end
    return rollChance(failureChance)
end

function TCCassetteDisassembleLoot.AwardDisassemblyXP(player, isElectronics)
    if not player or not player.getXp then return end
    local xpObj = player:getXp()
    if not xpObj or type(xpObj.AddXP) ~= "function" then return end

    if not TCCassetteDisassembleDefinitions then
        pcall(function() require "TCCassetteDisassembleDefinitions" end)
    end
    local xpAmount = 5
    if TCCassetteDisassembleDefinitions and TCCassetteDisassembleDefinitions.ExpGain then
        if isElectronics then
            xpAmount = TCCassetteDisassembleDefinitions.ExpGain.Electrical or xpAmount
        else
            xpAmount = TCCassetteDisassembleDefinitions.ExpGain.Cassette or xpAmount
        end
    elseif isElectronics then
        xpAmount = 10
    end

    local perkId = Perks and Perks.Electrical or findPerkByNameFragment("electr")
    if perkId then
        xpObj:AddXP(perkId, xpAmount)
    end
end

return TCCassetteDisassembleLoot

