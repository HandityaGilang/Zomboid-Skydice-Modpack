local SandboxSettings = require "config/IH_SandboxSettings"
local Config = require "config/IH_Config"
local DBG = require "IH_Debug"

local M = {}
local UNDER_DASH_FULL_TYPE = "ImmersiveHotwire.UnderDash"
local stableIdRequestMsByVehicle = {}

IH_UnderDashLoc = ItemBodyLocation.register("immersivehotwire:underdash")
local group = BodyLocations.getGroup("Human")
group:getOrCreateLocation(IH_UnderDashLoc)

function M.clamp(v, lo, hi)
    if v < lo then
        return lo
    end
    if v > hi then
        return hi
    end
    return v
end

function M.sanitizeSparkArgs(args)
    local dmgMin = tonumber(args.dmgMin) or 12
    local dmgMax = tonumber(args.dmgMax) or 20
    dmgMin = M.clamp(dmgMin, 0, 50)
    dmgMax = M.clamp(dmgMax, dmgMin, 50)

    local panicDelta = tonumber(args.panicDelta) or 20
    local discomfortDelta = tonumber(args.discomfortDelta) or 30
    panicDelta = M.clamp(panicDelta, 0, 100)
    discomfortDelta = M.clamp(discomfortDelta, 0, 100)

    return {
        dmgMin = dmgMin,
        dmgMax = dmgMax,
        panicDelta = panicDelta,
        discomfortDelta = discomfortDelta,
    }
end

function M.applySparkDamage(player, args)
    local bd = player:getBodyDamage()
    local dmgMin = args.dmgMin
    local dmgMax = args.dmgMax
    local dmg = dmgMin + ZombRand(0, math.max(0, (dmgMax - dmgMin) + 1))

    local left = bd:getBodyPart(BodyPartType.Hand_L)
    local right = bd:getBodyPart(BodyPartType.Hand_R)
    left:AddDamage(dmg)
    right:AddDamage(dmg)

    local stats = player:getStats()
    local panic = stats:get(CharacterStat.PANIC) or 0
    local discomfort = stats:get(CharacterStat.DISCOMFORT) or 0
    stats:set(CharacterStat.PANIC, M.clamp(panic + args.panicDelta, 0, 100))
    stats:set(CharacterStat.DISCOMFORT, M.clamp(discomfort + args.discomfortDelta, 0, 100))

    local moodles = player:getMoodles()
    moodles:Update()
end

function M.drainBattery(vehicle, drainPercent, doTransmit)
    if not vehicle then
        return
    end
    local part = vehicle:getPartById("Battery")
    if not part then
        return
    end

    local drain = (drainPercent or 3) / 100
    local item = part:getInventoryItem()
    if item then
        local beforeFloat = item:getCurrentUsesFloat() or 0
        local afterFloat = beforeFloat - drain
        if afterFloat < 0 then
            afterFloat = 0
        end
        item:setCurrentUsesFloat(afterFloat)
        if doTransmit == true then
            vehicle:transmitPartUsedDelta(part)
        end
    end
end

function M.applyHotwireSuccess(vehicle)
    vehicle:engineDoRunning()
    local md = vehicle:getModData()
    md.IH = md.IH or {}
    md.IH.alarmRisk = -1
    vehicle:transmitModData()
    DBG.log("ModData", "hotwireSuccess", { vehicleId = vehicle:getId() })
end

function M.getPerkLevel(player, perk)
    if not player then
        return 0
    end
    return player:getPerkLevel(perk) or 0
end

function M.getHotwireSkill(player)
    return M.getPerkLevel(player, Perks.Mechanics)
end

local function getStableHotwireId(vehicle)
    if not vehicle then
        return 0
    end
    local md = vehicle:getModData()
    local stableId = md and md.IH_StableId
    if type(stableId) == "number" and stableId > 0 then
        return stableId
    end
    return 0
end

local function nextRand(seed)
    return (seed * 1103515245 + 12345) % 2147483647
end

local function shuffle(list, seed)
    for i = #list, 2, -1 do
        seed = nextRand(seed + i)
        local j = (seed % i) + 1
        list[i], list[j] = list[j], list[i]
    end
end

local function getRoleIndexMapFromId(vehicleId)
    local roles = { Config.ROLES.BASE[1], Config.ROLES.BASE[2], Config.ROLES.BASE[3] }
    local extraRoles = { Config.ROLES.EXTRA[1] }
    local seed = vehicleId
    local count = (vehicleId % 2) + 3
    if count == 4 then
        seed = nextRand(seed + 7)
        local idx = (seed % #extraRoles) + 1
        roles[#roles + 1] = extraRoles[idx]
    end
    shuffle(roles, seed)
    local map = {}
    for i = 1, #roles do
        map[roles[i]] = i
    end
    return map, count
end

local function buildMigratedHotwireStateFromVanilla(vehicle)
    if not vehicle then
        return nil
    end
    local vehicleId = getStableHotwireId(vehicle)
    if type(vehicleId) ~= "number" or vehicleId <= 0 then
        return nil
    end
    local map, count = getRoleIndexMapFromId(vehicleId)
    local batteryIndex = map.battery
    local ignitionIndex = map.ignition
    if not batteryIndex or not ignitionIndex then
        return nil
    end
    local wires = {}
    for i = 1, count do
        wires[i] = "cut"
    end
    wires[batteryIndex] = { target = ignitionIndex }
    wires[ignitionIndex] = { target = ignitionIndex }
    local state = {
        screw1Done = true,
        screw2Done = true,
        version = SandboxSettings.LEGACY_WIRE_MIGRATION_VERSION,
        wires = wires,
    }
    DBG.log("State", "migrateBuild", { vehicleId = vehicle:getId(), wires = count })
    return state
end

local function applyMigratedStateLocal(vehicle, state)
    if not vehicle or type(state) ~= "table" then
        return false
    end
    local md = vehicle:getModData()
    md.IH = md.IH or {}
    md.IH.screw1Done = state.screw1Done == true
    md.IH.screw2Done = state.screw2Done == true
    md.IH._version = state.version
    md.IH.wires = state.wires
    md.IH.cuts = nil
    md.IH.taped = nil
    md.IH.connections = nil
    md.IH._rev = (md.IH._rev or 0) + 1
    vehicle:transmitModData()
    DBG.log("State", "migrateApply", { vehicleId = vehicle:getId() })
    return true
end

function M.ensureHotwiredMigrated(vehicle, playerObj, sentById, debounceMs, pendingMigrationById, nowFn)
    if not vehicle or not vehicle:isHotwired() then
        return false
    end

    local sent = sentById or {}
    local debounce = tonumber(debounceMs) or 250
    local getNow = nowFn or getTimestampMs or function()
        return os.time() * 1000
    end

    local function shouldDebounce(vehicleId)
        local now = getNow()
        local last = sent[vehicleId] or 0
        if (now - last) < debounce then
            return true
        end
        sent[vehicleId] = now
        return false
    end

    local function sendUpdateState(player, vehicleId, state)
        local payload = {
            vehicleId = vehicleId,
            state = state,
        }
        if player then
            sendClientCommand(player, "IH", "UpdateState", payload)
            return
        end
        sendClientCommand("IH", "UpdateState", payload)
    end

    local function requestStableId(player, vehicleId)
        local now = getNow()
        local last = stableIdRequestMsByVehicle[vehicleId] or 0
        if (now - last) < debounce then
            return true
        end
        stableIdRequestMsByVehicle[vehicleId] = now
        local payload = { vehicleId = vehicleId }
        if player then
            sendClientCommand(player, "IH", "EnsureStableId", payload)
        else
            sendClientCommand("IH", "EnsureStableId", payload)
        end
        DBG.log("State", "migrateWaitStableId", { vehicleId = vehicleId })
        return true
    end

    local md = vehicle:getModData()
    local ih = md.IH
    if type(ih) == "table" then
        if ih._version == SandboxSettings.DATA_VERSION then
            return false
        end
        if ih._version == SandboxSettings.LEGACY_WIRE_MIGRATION_VERSION then
            local upgradeState = { version = SandboxSettings.DATA_VERSION }
            if isClient() then
                local vehicleId = vehicle:getId()
                if shouldDebounce(vehicleId) then
                    return true
                end
                sendUpdateState(playerObj, vehicleId, upgradeState)
                return true
            end
            return M.applyHotwireState(vehicle, upgradeState, nil, SandboxSettings.DATA_VERSION, playerObj)
        end
    end

    local state = buildMigratedHotwireStateFromVanilla(vehicle)
    if not state then
        if isClient() then
            local stableId = getStableHotwireId(vehicle)
            if type(stableId) ~= "number" or stableId <= 0 then
                return requestStableId(playerObj, vehicle:getId())
            end
        end
        return false
    end

    if isClient() then
        local vehicleId = vehicle:getId()
        if pendingMigrationById then
            pendingMigrationById[vehicleId] = state
        end
        if shouldDebounce(vehicleId) then
            return true
        end
        sendUpdateState(playerObj, vehicleId, state)
        return true
    end

    return applyMigratedStateLocal(vehicle, state)
end

local function findWornUnderDash(player)
    local wornItems = player:getWornItems()
    for i = 0, wornItems:size() - 1 do
        local item = wornItems:get(i):getItem()
        if item and item:getFullType() == UNDER_DASH_FULL_TYPE then
            return item
        end
    end
    return nil
end

local function removeUnderDashItem(player, item)
    local container = item:getContainer()
    player:removeAttachedItem(item)
    if player:isEquipped(item) then
        player:removeFromHands(item)
    end
    player:removeWornItem(item, false)
    container:DoRemoveItem(item)
end

function M.IH_UnderDash_Clear(player)
    if not player then
        return false
    end
    local removed = false
    local inventory = player:getInventory()
    while true do
        local item = findWornUnderDash(player)
        if not item then
            item = inventory:getFirstTypeRecurse(UNDER_DASH_FULL_TYPE)
        end
        if not item then
            break
        end
        removeUnderDashItem(player, item)
        removed = true
    end
    if removed then
        triggerEvent("OnClothingUpdated", player)
    end
    return removed
end

function M.IH_UnderDash_Apply(player)
    if not player then
        return nil
    end
    M.IH_UnderDash_Clear(player)
    local inventory = player:getInventory()
    local item = inventory:AddItem(UNDER_DASH_FULL_TYPE)
    if not item then
        return nil
    end
    player:setWornItem(IH_UnderDashLoc, item)
    triggerEvent("OnClothingUpdated", player)
    return item
end

function M.scaleAlarmRisk(amount, player)
    local scaled = tonumber(amount) or 0
    if scaled == 0 then
        return 0
    end
    if M.getHotwireSkill(player) >= 2 then
        return scaled * 0.5
    end
    return scaled
end

local function sanitizeWireEntry(entry, maxWires)
    if entry == "cut" or entry == "taped" then
        return entry
    end
    if type(entry) == "table" then
        local target = entry.target
        if type(target) == "number" then
            local idx = math.floor(target)
            if idx >= 1 and idx <= maxWires then
                return { target = idx }
            end
        end
    end
    return nil
end

local function sanitizeWires(wires, maxWires)
    local sanitized = {}
    for i = 1, maxWires do
        local entry = sanitizeWireEntry(wires[i], maxWires)
        if entry ~= nil then
            sanitized[i] = entry
        end
    end
    for i = 1, maxWires do
        local entry = sanitized[i]
        if type(entry) == "table" then
            local target = entry.target
            local targetEntry = sanitized[target]
            if type(targetEntry) ~= "table" then
                sanitized[target] = { target = target }
            end
        end
    end
    return sanitized
end

local function wireEntryEqual(a, b)
    if type(a) ~= type(b) then
        return false
    end
    if type(a) == "table" then
        return a.target == b.target
    end
    return a == b
end

local function wireStateEqual(a, b, maxWires)
    if type(a) ~= "table" or type(b) ~= "table" then
        return type(a) ~= "table" and type(b) ~= "table"
    end
    for i = 1, maxWires do
        if not wireEntryEqual(a[i], b[i]) then
            return false
        end
    end
    return true
end

function M.applyHotwireState(vehicle, state, maxWires, dataVersion, player)
    if not vehicle or type(state) ~= "table" then
        return false
    end
    local modData = vehicle:getModData()
    modData.IH = modData.IH or {}
    local previousVersion = modData.IH._version
    local changed = false
    if vehicle:isHotwired()
        and previousVersion ~= SandboxSettings.DATA_VERSION
        and modData.IH.alarmRisk ~= -1 then
        modData.IH.alarmRisk = -1
        changed = true
    end

    if state.screw1Done ~= nil then
        local value = state.screw1Done == true
        if modData.IH.screw1Done ~= value then
            modData.IH.screw1Done = value
            changed = true
            if value then
                M.IH_AddAlarmRisk(vehicle, SandboxSettings.ALARM.ADD_SCREW, player)
            end
        end
    end
    if state.screw2Done ~= nil then
        local value = state.screw2Done == true
        if modData.IH.screw2Done ~= value then
            modData.IH.screw2Done = value
            changed = true
            if value then
                M.IH_AddAlarmRisk(vehicle, SandboxSettings.ALARM.ADD_SCREW, player)
            end
        end
    end

    local version = (type(dataVersion) == "string" and dataVersion) or SandboxSettings.DATA_VERSION
    if type(state.version) == "string" then
        if modData.IH._version ~= state.version then
            modData.IH._version = state.version
            changed = true
        end
    elseif modData.IH._version ~= version then
        modData.IH._version = version
        changed = true
    end
    if type(state.wires) == "table" then
        local count = maxWires or #state.wires
        if count < 0 then
            count = 0
        end
        local sanitized = sanitizeWires(state.wires, count)
        if not wireStateEqual(modData.IH.wires, sanitized, count) then
            local addedCuts = 0
            local oldWires = modData.IH.wires
            for i = 1, count do
                if sanitized[i] == "cut" and (type(oldWires) ~= "table" or oldWires[i] ~= "cut") then
                    addedCuts = addedCuts + 1
                end
            end
            modData.IH.wires = sanitized
            modData.IH.cuts = nil
            modData.IH.taped = nil
            modData.IH.connections = nil
            changed = true
            if addedCuts > 0 then
                M.IH_AddAlarmRisk(vehicle, SandboxSettings.ALARM.ADD_CUT * addedCuts, player)
            end
        end
    end

    if changed then
        modData.IH._rev = (modData.IH._rev or 0) + 1
        vehicle:transmitModData()
        local wiresCount = 0
        if type(modData.IH.wires) == "table" then
            wiresCount = #modData.IH.wires
        end
        DBG.log("ModData", "applyHotwireState", {
            rev = modData.IH._rev,
            screw1 = modData.IH.screw1Done == true,
            screw2 = modData.IH.screw2Done == true,
            vehicleId = vehicle:getId(),
            wires = wiresCount,
        })
    end
    return changed
end

local function IH_AddAlarmRisk(vehicle, amount, player)
    if not vehicle then
        return false
    end

    local md = vehicle:getModData()
    md.IH = md.IH or {}
    local ih = md.IH

    if ih.alarmRisk == nil then
        if ZombRand(100) < 40 then
            ih.alarmRisk = -1
            vehicle:transmitModData()
            return false
        end
    end

    local oldRisk = tonumber(ih.alarmRisk)
    if oldRisk == -1 then
        return false
    end
    oldRisk = oldRisk or 0
    local scaled = M.scaleAlarmRisk(amount, player)
    local risk = oldRisk + scaled
    if risk > SandboxSettings.ALARM.RISK_MAX then
        risk = SandboxSettings.ALARM.RISK_MAX
    end
    ih.alarmRisk = risk
    if vehicle:isAlarmed() then
        vehicle:transmitModData()
        return false
    end

    local triggered = ZombRand(100) < risk
    if triggered then
        vehicle:setAlarmed(true)
        vehicle:triggerAlarm()
        ih.alarmRisk = 0
    end

    vehicle:transmitModData()
    return triggered
end

M.IH_AddAlarmRisk = IH_AddAlarmRisk

function M.setHotwired(vehicle)
    vehicle:cheatHotwire(true, false)
end

function M.clearHotwired(vehicle)
    vehicle:cheatHotwire(false, false)

    local md = vehicle:getModData()
    local ih = md.IH
    if type(ih) ~= "table" then
        ih = {}
    end
    if type(ih.wires) ~= "table" then
        ih.wires = {}
    end
    ih.cuts = nil
    ih.taped = nil
    ih.connections = nil
    ih._rev = (ih._rev or 0) + 1
    md.IH = ih
    DBG.log("ModData", "clearHotwired", { vehicleId = vehicle:getId(), rev = ih._rev })
end

function M.hasBatteryCharge(vehicle)
    if not vehicle then
        return false
    end
    local part = vehicle:getPartById("Battery")
    if not part then
        return false
    end

    local item = part:getInventoryItem()
    if item then
        local usesFloat = item:getCurrentUsesFloat()
        if usesFloat ~= nil then
            return usesFloat > 0
        end
        local uses = item:getCurrentUses()
        if uses ~= nil then
            return uses > 0
        end
    end

    local delta = part:getDelta()
    if delta ~= nil then
        return delta > 0
    end
    local content = part:getContainerContentAmount()
    if content ~= nil then
        return content > 0
    end

    return true
end

return M


