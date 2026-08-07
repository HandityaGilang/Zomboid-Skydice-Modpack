local MAX_WIRES = 4
local RATE_LIMIT_MS = 150
local UPDATESTATE_RATE_LIMIT_MS = 150
local lastUpdateMsByPlayer = {}
local lastUpdateStateMsByPlayer = {}
local SandboxSettings = require "config/IH_SandboxSettings"
local Actions = require "gameplay/IH_Actions"
local Config = require "config/IH_Config"
local DBG = require "IH_Debug"
local DATA_VERSION = SandboxSettings.DATA_VERSION
local SPARK_CMD_DAMAGE = "SparkDamage"
local SPARK_CMD_DRAIN = "SparkDrainBattery"
local SPARK_CMD_APPLY = "SparkApply"
local ALARM_CMD_ADD = "AddAlarmRisk"
local HOTWIRE_CMD_SUCCESS = "HotwireSuccess"
local HOTWIRE_CMD_SET = "SetHotwired"
local HOTWIRE_CMD_CLEAR = "ClearHotwired"
local STABLE_ID_CMD_ENSURE = "EnsureStableId"
local UNSCREW_REWARD_CMD = "UnscrewReward"

local function getNowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return os.time() * 1000
end

local function ensureStableId(vehicle)
    if not vehicle then
        return nil
    end
    local md = vehicle:getModData()
    if type(md.IH_StableId) == "number" and md.IH_StableId > 0 then
        return md.IH_StableId
    end
    local stableId = ZombRand(2147483647) + 1
    md.IH_StableId = stableId
    DBG.log("StableId", "create", { stableId = stableId, vehicleId = vehicle:getId() })
    vehicle:transmitModData()
    return stableId
end

local function getBatteryPartAndItem(vehicle)
    if not vehicle then
        return nil, nil, "vehicleNil=true"
    end
    local part = vehicle:getPartById("Battery")
    if not part then
        return nil, nil
    end
    local item = part:getInventoryItem()
    return part, item
end

local function getPlayerKey(player)
    if player then
        local id = player:getOnlineID()
        if id then
            return id
        end
        local name = player:getUsername()
        if name then
            return name
        end
    end
    return tostring(player)
end

local function isRateLimited(player)
    local key = getPlayerKey(player)
    if not key then
        return true
    end
    local now = getNowMs()
    local last = lastUpdateMsByPlayer[key]
    if last and (now - last) < RATE_LIMIT_MS then
        return true
    end
    lastUpdateMsByPlayer[key] = now
    return false
end

local function isUpdateStateRateLimited(player)
    local key = getPlayerKey(player)
    if not key then
        return true
    end
    local now = getNowMs()
    local last = lastUpdateStateMsByPlayer[key]
    if last and (now - last) < UPDATESTATE_RATE_LIMIT_MS then
        return true
    end
    lastUpdateStateMsByPlayer[key] = now
    return false
end

local function handleSparkDamage(player, args)
    local sanitized = Actions.sanitizeSparkArgs(args)
    Actions.applySparkDamage(player, sanitized)
end

local function handleSparkDrainBattery(player, args)
    if not player then
        return
    end

    local drainPercent = tonumber(args.drainPercent) or 3
    drainPercent = Actions.clamp(drainPercent, 0, 100)

    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    Actions.drainBattery(vehicle, drainPercent, true)
end

local function canSparkNow(player, args)
    local vehicle = player:getVehicle()
    if not vehicle then
        return false
    end
    if args.vehicleId and vehicle:getId() ~= args.vehicleId then
        return false
    end
    return Actions.hasBatteryCharge(vehicle)
end

local function onClientCommand(module, command, player, args)
    if module ~= "IH" then
        return
    end

    if not player then
        return
    end
    args = args or {}
    if command == STABLE_ID_CMD_ENSURE then
        if type(args.vehicleId) ~= "number" then
            return
        end
        local vehicle = player:getVehicle()
        if not vehicle then
            return
        end
        if vehicle:getId() ~= args.vehicleId then
            return
        end
        ensureStableId(vehicle)
        return
    end
    if command == SPARK_CMD_DAMAGE then
        if isRateLimited(player) then
            return
        end
        if not canSparkNow(player, args) then
            return
        end
        handleSparkDamage(player, args)
        return
    end
    if command == SPARK_CMD_DRAIN then
        if isRateLimited(player) then
            return
        end
        if not canSparkNow(player, args) then
            return
        end
        handleSparkDrainBattery(player, args)
        return
    end
    if command == SPARK_CMD_APPLY then
        if isRateLimited(player) then
            return
        end
        if not canSparkNow(player, args) then
            return
        end

        local spark = Config.SPARK or {}
        local drainPercent = tonumber(spark.BATTERY_DRAIN) or 3
        drainPercent = Actions.clamp(drainPercent, 0, 100)

        local vehicle = player:getVehicle()
        if not vehicle then
            return
        end
        Actions.drainBattery(vehicle, drainPercent, true)

        local sanitized = Actions.sanitizeSparkArgs({
            dmgMin = spark.HAND_DAMAGE_MIN,
            dmgMax = spark.HAND_DAMAGE_MAX,
            panicDelta = spark.PANIC_DELTA,
            discomfortDelta = spark.DISCOMFORT_DELTA,
        })
        Actions.applySparkDamage(player, sanitized)
        Actions.IH_AddAlarmRisk(vehicle, SandboxSettings.ALARM.ADD_SPARK, player)
        return
    end
    if command == ALARM_CMD_ADD then
        if isRateLimited(player) then
            return
        end
        local amount = tonumber(args.amount) or 0
        if amount == 0 then
            return
        end
        local vehicle = player:getVehicle()
        if not vehicle then
            return
        end
        if args.vehicleId and vehicle:getId() ~= args.vehicleId then
            return
        end
        Actions.IH_AddAlarmRisk(vehicle, amount, player)
        return
    end
    if command == "RequestTools" then
        if isRateLimited(player) then
            return
        end
        local tools = SandboxSettings.buildToolsFromOptions()
        sendServerCommand(player, "IH", "ToolsResponse", tools)
        return
    end

    if command == "ClearVehicleModData" then
        if isRateLimited(player) then
            return
        end
        if not player:isAccessLevel("admin") and not isDebugEnabled() then
            return
        end
        if not args.vehicleId then
            return
        end
        local target = getVehicleById(args.vehicleId)
        if not target then
            return
        end
        ensureStableId(target)
        local md = target:getModData()
        local version = (type(md.IH) == "table" and md.IH._version) or nil
        md.IH = nil
        if version ~= nil then
            md.IH = { _version = version }
        end
        Actions.clearHotwired(target)
        target:transmitModData()
        target:transmitEngine()
        return
    end

    if command == HOTWIRE_CMD_CLEAR then
        if isRateLimited(player) then
            return
        end
        if not args.vehicleId then
            return
        end
        local target = getVehicleById(args.vehicleId)
        if not target then
            return
        end
        ensureStableId(target)
        local md = target:getModData()
        local ih = md.IH
        local beforeRev = (type(ih) == "table" and ih._rev) or 0
        local beforeHotwired = target:isHotwired()
        Actions.clearHotwired(target)
        local afterRev = (type(md.IH) == "table" and md.IH._rev) or 0
        local afterHotwired = target:isHotwired()
        target:transmitModData()
        target:transmitEngine()
        return
    end

    if command == UNSCREW_REWARD_CMD then
        if isRateLimited(player) then return end

        if type(args.vehicleId) == "number" then
            local target = getVehicleById(args.vehicleId)
            if not target then return end
        end

        local item = player:getInventory():AddItem("Base.Screws")
        sendAddItemToContainer(player:getInventory(), item)
        return
    end

    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    ensureStableId(vehicle)
    if args.vehicleId then
        if vehicle:getId() ~= args.vehicleId then
            return
        end
    end

    if command == HOTWIRE_CMD_SUCCESS then
        if isRateLimited(player) then
            return
        end
        Actions.applyHotwireSuccess(vehicle)
        if args and args.drainPercent ~= nil then
            local drainPercent = tonumber(args.drainPercent) or 0
            drainPercent = Actions.clamp(drainPercent, 0, 100)
            Actions.drainBattery(vehicle, drainPercent, true)
        end
        return
    end

    if command == HOTWIRE_CMD_SET then
        if isRateLimited(player) then
            return
        end
        Actions.setHotwired(vehicle)
        return
    end

    if command == "UpdateState" then
        if type(args.state) ~= "table" then
            return
        end
        if isUpdateStateRateLimited(player) then
            return
        end
        Actions.applyHotwireState(vehicle, args.state, MAX_WIRES, DATA_VERSION, player)
        DBG.log("Net", "UpdateState", { vehicleId = vehicle:getId() })
        return
    end

end

Events.OnClientCommand.Add(onClientCommand)

local function onClientCommandBlockStart(module, command, player, args)
    if module ~= "IH" or command ~= "BlockStart" then
        return
    end
    if not player or type(args) ~= "table" then
        return
    end
    local vid = args.vehicleId
    if type(vid) ~= "number" then
        return
    end
    local playerVehicle = player:getVehicle()
    if not playerVehicle then
        return
    end
    if playerVehicle:getId() ~= vid then
        return
    end
    if playerVehicle:getSeat(player) ~= 0 then
        return
    end
    ensureStableId(playerVehicle)
    local untilMs = tonumber(args.untilMs) or 0
    if untilMs <= 0 then
        return
    end

    local now = getNowMs()
    local minUntil = now + 400 -- BLOCK_MS
    if untilMs < minUntil then
        untilMs = minUntil
    end
    local md = playerVehicle:getModData()
    md.IH = md.IH or {}
    local ih = md.IH
    local changed = false
    if untilMs > (ih.blockStartUntilMs or 0) then
        ih.blockStartUntilMs = untilMs
        changed = true
    end
    if ih.blockArmed ~= true then
        ih.blockArmed = true
        changed = true
    end
    ih.batterySnapUntilMs = ih.blockStartUntilMs
    local part, item = getBatteryPartAndItem(playerVehicle)
    if item and item:getCurrentUsesFloat() ~= nil then
        if ih.batterySnap == nil then
            ih.batterySnap = item:getCurrentUsesFloat()
            changed = true
        end
    end
    if playerVehicle:isStarting() then
        playerVehicle:engineDoStartingFailed()
        playerVehicle:engineDoIdle()
    end
    if changed then
        playerVehicle:transmitModData()
    end
end

Events.OnClientCommand.Add(onClientCommandBlockStart)

local function serverGuardPlayer(player)
    if not player then
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    ensureStableId(vehicle)
    local md = vehicle:getModData()
    local ih = md and md.IH
    local untilMs = ih and ih.blockStartUntilMs
    if type(untilMs) ~= "number" then
        return
    end
    local now = getNowMs()
    if now >= untilMs then
        if ih.blockStartUntilMs ~= nil or ih.batterySnap ~= nil or ih.batterySnapUntilMs ~= nil or ih.blockArmed ~= nil then
            ih.blockStartUntilMs = nil
            ih.batterySnap = nil
            ih.batterySnapUntilMs = nil
            ih.blockArmed = nil
            vehicle:transmitModData()
        end
        return
    end
    if ih.blockArmed == true then
        if vehicle:isStarting() then
            vehicle:engineDoStartingFailed()
            vehicle:engineDoIdle()
        end
    end
    local part, item = getBatteryPartAndItem(vehicle)
    if item and item:getCurrentUsesFloat() ~= nil then
        if ih.batterySnap == nil or now >= (ih.batterySnapUntilMs or 0) then
            ih.batterySnap = item:getCurrentUsesFloat()
            ih.batterySnapUntilMs = untilMs
            vehicle:transmitModData()
        elseif ih.batterySnap ~= nil and item:getCurrentUsesFloat() < ih.batterySnap then
            item:setCurrentUsesFloat(ih.batterySnap)
            vehicle:transmitPartUsedDelta(part)
        end
    end
end

local function serverGuardTick()
    local players = getOnlinePlayers()
    if not players then
        return
    end
    for i = 0, players:size() - 1 do
        serverGuardPlayer(players:get(i))
    end
end

Events.OnTick.Add(serverGuardTick)


