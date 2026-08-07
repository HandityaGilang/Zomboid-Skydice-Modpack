-- TrueMoozic - Music Fan trait starter kit (server-side)
-- Run on dedicated server and SP local authority; skip pure client.
if isClient() then return end

require "TCMusicDefenitions"

pcall(function() require "TCMusicModDetector" end)

local function toArrayFromMap(map, filter)
    local list = {}
    if not map then return list end
    for fullType, _ in pairs(map) do
        if type(fullType) == "string" and (not filter or filter(fullType)) then
            table.insert(list, fullType)
        end
    end
    return list
end

local function pickRandom(list)
    if not list or #list == 0 then return nil end
    return list[ZombRand(1, #list + 1)]
end

local function resolveCassetteFullType(maybeType, modID)
    if not maybeType or type(maybeType) ~= "string" then return nil end
    if maybeType:find("%.", 1, true) then
        return maybeType
    end

    if modID and type(modID) == "string" then
        local withMod = modID .. "." .. maybeType
        if getScriptManager():FindItem(withMod) then
            return withMod
        end
    end

    local withBase = "Base." .. maybeType
    if getScriptManager():FindItem(withBase) then
        return withBase
    end

    local allItems = getAllItems()
    if allItems then
        for i = 0, allItems:size() - 1 do
            local item = allItems:get(i)
            if item then
                local name = item:getName()
                if name == maybeType then
                    local full = item:getFullName()
                    if full and getScriptManager():FindItem(full) then
                        return full
                    end
                end
            end
        end
    end

    return nil
end

local function getRandomWalkmanType()
    local list = toArrayFromMap(TCMusic and TCMusic.WalkmanPlayer or nil, function(ft)
        return ft:find("TCWalkman", 1, true) ~= nil
    end)
    return pickRandom(list)
end

local function setBatteryOnDevice(deviceItem, inventory)
    if not deviceItem or not inventory then return end
    local deviceData = deviceItem:getDeviceData()
    if not deviceData or not deviceData.getIsBatteryPowered or not deviceData:getIsBatteryPowered() then
        return
    end
    if deviceData.getHasBattery and deviceData:getHasBattery() then
        return
    end

    local battery = inventory:AddItem("Base.Battery")
    if not battery then return end

    if deviceData.addBattery then
        deviceData:addBattery(battery)
    end

    local md = deviceItem:getModData()
    md.tcmusic = md.tcmusic or {}
    md.tcmusic.batteryHas = true
    if deviceData.getPower then
        md.tcmusic.batteryPower = deviceData:getPower()
    end

    if battery:getContainer() then
        battery:getContainer():Remove(battery)
    end
end

local function pickHeadphonesItem(inventory)
    local options = { "Base.Headphones", "Base.Earbuds" }
    local picks = {}
    for _, fullType in ipairs(options) do
        if getScriptManager():FindItem(fullType) then
            table.insert(picks, fullType)
        end
    end
    local choice = pickRandom(picks)
    if not choice then return nil end
    return inventory:AddItem(choice)
end

local function setHeadphonesOnWalkman(deviceItem, inventory)
    if not deviceItem or not inventory then return end
    local deviceData = deviceItem:getDeviceData()
    if not deviceData or not deviceData.getHeadphoneType then return end
    if deviceData:getHeadphoneType() >= 0 then return end

    local headphones = pickHeadphonesItem(inventory)
    if not headphones then return end

    if deviceData.addHeadphones then
        deviceData:addHeadphones(headphones)
    end

    local md = deviceItem:getModData()
    md.tcmusic = md.tcmusic or {}
    if deviceData.getHeadphoneType then
        md.tcmusic.headphoneType = deviceData:getHeadphoneType()
        md.tm_headphoneType = md.tcmusic.headphoneType
        md.tm_hasHeadphones = md.tcmusic.headphoneType >= 0
    end

    if headphones:getContainer() then
        headphones:getContainer():Remove(headphones)
    end
end

local function pickRandomCassetteFullType()
    local candidates = {}
    if TCMusicModDetector and TCMusicModDetector.GetAllCassettes then
        if TCMusicModDetector.GetDetectedModCount and TCMusicModDetector.GetDetectedModCount() == 0 then
            pcall(function() TCMusicModDetector.DetectMusicMods() end)
        end
        local all = TCMusicModDetector.GetAllCassettes()
        for _, cassette in ipairs(all) do
            local ft = cassette and cassette.fullType or nil
            local modID = cassette and cassette.modID or nil
            if ft and ft:lower():find("cassette", 1, true) and not ft:lower():find("cassettecase", 1, true) then
                local resolved = resolveCassetteFullType(ft, modID)
                if resolved then
                    table.insert(candidates, resolved)
                end
            end
        end
    end
    local chosen = pickRandom(candidates)
    if chosen and getScriptManager():FindItem(chosen) then
        return chosen
    end
    return "Tsarcraft.CassetteMainTheme"
end

local function getCharacterId(player)
    if not player then return nil end
    local desc = player.getDescriptor and player:getDescriptor() or nil
    if desc and desc.getID then
        return desc:getID()
    end
    if player.getID then
        return player:getID()
    end
    return nil
end

TCStartWithDevice = TCStartWithDevice or {}

-- Music Fan trait starter kit: walkman (headphones + battery fitted) and
-- 3 random cassettes. Granted once per character.
local function giveMusicFanKit(player)
    if not player or player:isDead() then return false end
    if not (TCMusic and TCMusic.playerHasTrait and TCMusic.playerHasTrait(player, "truemoozicfan")) then return true end
    local md = player:getModData()
    local charId = getCharacterId(player)
    if not charId then return false end
    if md.tm_musicfan_kit_given_id == charId then return true end

    local inventory = player:getInventory()
    if not inventory then return false end

    local deviceType = getRandomWalkmanType()
    if deviceType and getScriptManager():FindItem(deviceType) then
        local deviceItem = inventory:AddItem(deviceType)
        if deviceItem then
            local itemMd = deviceItem:getModData()
            itemMd.tcmusic = itemMd.tcmusic or {}
            itemMd.tcmusic.deviceType = "InventoryItem"
            itemMd.tcmusic.isPlaying = false
            setBatteryOnDevice(deviceItem, inventory)
            setHeadphonesOnWalkman(deviceItem, inventory)
            if deviceItem.sync then
                deviceItem:sync()
            end
            if isServer() and sendAddItemToContainer then
                sendAddItemToContainer(inventory, deviceItem)
            end
        end
    end

    local given = {}
    for _ = 1, 3 do
        local cassetteType = nil
        -- A few retries to avoid handing out duplicates.
        for _ = 1, 5 do
            local pick = pickRandomCassetteFullType()
            if pick and not given[pick] then
                cassetteType = pick
                break
            end
            cassetteType = cassetteType or pick
        end
        if cassetteType and getScriptManager():FindItem(cassetteType) then
            given[cassetteType] = true
            local tape = inventory:AddItem(cassetteType)
            if tape and isServer() and sendAddItemToContainer then
                sendAddItemToContainer(inventory, tape)
            end
        end
    end

    md.tm_musicfan_kit_given_id = charId
    return true
end

TCStartWithDevice.GiveMusicFanKit = giveMusicFanKit
-- Back-compat alias (TCServerCommands falls back to GiveStartDevice).
TCStartWithDevice.GiveStartDevice = giveMusicFanKit

local function requestStartDevice(player)
    giveMusicFanKit(player)
end

TCStartWithDevice.RequestStartDevice = requestStartDevice

local function onCreatePlayer(_index, player)
    requestStartDevice(player)
end

local function onNewPlayer(_index, player)
    -- Some MP servers fire OnNewPlayer but not OnCreatePlayer
    requestStartDevice(player)
end

local function onNewGame(player, _square)
    -- Fires after character is fully created/loaded; best place for start items
    requestStartDevice(player)
end

if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(onCreatePlayer)
end
if Events and Events.OnNewPlayer then
    Events.OnNewPlayer.Add(onNewPlayer)
end
if Events and Events.OnNewGame then
    Events.OnNewGame.Add(onNewGame)
end

-- Safety net: the creation events can fire BEFORE the character's traits
-- are applied (trait check fails, kit skipped). Sweep local players every
-- minute; the once-per-character modData stamp keeps this idempotent.
local function kitSweep()
    if isServer() then
        local players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                giveMusicFanKit(players:get(i))
            end
        end
    else
        local p = getPlayer()
        if p then giveMusicFanKit(p) end
    end
end

Events.EveryOneMinute.Add(kitSweep)

