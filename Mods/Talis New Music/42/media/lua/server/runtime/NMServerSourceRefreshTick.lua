-- Server authoritative source refresh pass for moving world-active registry entries.
NMServerSourceRefreshTick = NMServerSourceRefreshTick or {}
local SourceRefreshDiagnostics = NMServerSourceRefreshDiagnostics

local function asNumber(value)
    local n = tonumber(value)
    if n == nil then
        return nil
    end
    return n
end

local function nowRealMs()
    if getTimestampMs then
        local ms = tonumber(getTimestampMs())
        if ms then return ms end
    end
    if getTimestamp then
        local ts = tonumber(getTimestamp())
        if ts then return ts * 1000 end
    end
    return 0
end

local function safeCall(fn)
    if type(pcall) ~= "function" then
        return false, nil
    end
    return pcall(fn)
end

local function readVehiclesSize(vehicles)
    if not vehicles then
        return 0
    end
    local okA, countA = safeCall(function()
        return vehicles.size and vehicles:size() or nil
    end)
    if okA and tonumber(countA) then
        return math.max(0, math.floor(tonumber(countA) or 0))
    end
    local okB, countB = safeCall(function()
        return vehicles.size and vehicles.size(vehicles) or nil
    end)
    if okB and tonumber(countB) then
        return math.max(0, math.floor(tonumber(countB) or 0))
    end
    return 0
end

local function readVehiclesAtMode(vehicles, idx, mode)
    if mode == "raw_index" then
        return safeCall(function()
            return vehicles[idx]
        end)
    end
    return false, nil
end

local ATTEMPT_PRIORITY = {
    iterator = 1,
    to_array = 2
}

local function readClassName(obj)
    if not obj then
        return "nil"
    end
    local okClassText, classText = safeCall(function()
        local cls = obj:getClass()
        return cls and tostring(cls) or nil
    end)
    if okClassText and tostring(classText or "") ~= "" then
        return tostring(classText)
    end
    local okString, asString = safeCall(function()
        return tostring(obj)
    end)
    if okString and tostring(asString or "") ~= "" then
        return tostring(asString)
    end
    return "unknown"
end

local function makeAttempt(name, sizeRef)
    return {
        attemptName = tostring(name),
        nonNil = 0,
        sizeRef = tonumber(sizeRef) or 0,
        errors = 0,
        sampleSqlIds = {},
        sampleVehicleIds = {},
        pairs = {},
        iterated = 0,
        nilSlots = 0,
        indexBase = "none"
    }
end

local function captureVehicle(attempt, vehicle)
    if not vehicle then
        attempt.nilSlots = attempt.nilSlots + 1
        return
    end
    attempt.nonNil = attempt.nonNil + 1
    local sqlId = NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(vehicle) or ""
    local vehicleId = NMVehicleHelpers and NMVehicleHelpers.getVehicleIdString and NMVehicleHelpers.getVehicleIdString(vehicle) or ""
    if sqlId ~= "" and vehicleId ~= "" then
        attempt.pairs[#attempt.pairs + 1] = { sql = tostring(sqlId), id = tostring(vehicleId) }
    end
    if #attempt.sampleSqlIds < 5 then
        attempt.sampleSqlIds[#attempt.sampleSqlIds + 1] = tostring(sqlId ~= "" and sqlId or "nil")
    end
    if #attempt.sampleVehicleIds < 5 then
        attempt.sampleVehicleIds[#attempt.sampleVehicleIds + 1] = tostring(vehicleId ~= "" and vehicleId or "nil")
    end
end

local function collectFromVehiclesSource(label, vehicles, outMap)
    local report = {
        label = tostring(label or "unknown"),
        sizeReported = 0,
        iteratedSlots = 0,
        nonNilVehicles = 0,
        nilSlots = 0,
        getErrors = 0,
        readModeUsed = "none",
        indexBaseUsed = "none",
        sampleSqlIds = {},
        sampleVehicleIds = {},
        attemptSummary = "",
        attempts = {},
        vehiclesClass = "nil"
    }
    if not vehicles then
        return report
    end

    report.vehiclesClass = readClassName(vehicles)
    local size = readVehiclesSize(vehicles)
    report.sizeReported = size
    if size <= 0 then
        return report
    end

    local best = nil
    local function considerBest(candidate)
        if not best then
            best = candidate
            return
        end
        if candidate.nonNil > best.nonNil then
            best = candidate
            return
        end
        if candidate.nonNil == best.nonNil and candidate.errors < best.errors then
            best = candidate
            return
        end
        if candidate.nonNil == best.nonNil and candidate.errors == best.errors then
            local pa = ATTEMPT_PRIORITY[candidate.attemptName] or 999
            local pb = ATTEMPT_PRIORITY[best.attemptName] or 999
            if pa < pb then
                best = candidate
            end
        end
    end

    -- Iterator traversal.
    do
        local a = makeAttempt("iterator", size)
        local okIt, it = safeCall(function()
            return vehicles.iterator and vehicles:iterator() or nil
        end)
        if not okIt or not it then
            a.errors = a.errors + 1
        else
            while true do
                local okHasNext, hasNext = safeCall(function()
                    return it.hasNext and it:hasNext() or false
                end)
                if not okHasNext then
                    a.errors = a.errors + 1
                    break
                end
                if hasNext ~= true then
                    break
                end
                a.iterated = a.iterated + 1
                local okNext, vehicle = safeCall(function()
                    return it.next and it:next() or nil
                end)
                if not okNext then
                    a.errors = a.errors + 1
                end
                captureVehicle(a, vehicle)
                if a.iterated > 1024 then
                    break
                end
            end
        end
        report.attempts[#report.attempts + 1] = a
        considerBest(a)
    end

    -- toArray traversal.
    do
        local a = makeAttempt("to_array", size)
        local okArr, arr = safeCall(function()
            return vehicles.toArray and vehicles:toArray() or nil
        end)
        if not okArr or not arr then
            a.errors = a.errors + 1
        else
            local arrSize = 0
            local okArrSizeA, cA = safeCall(function()
                return arr.size and arr:size() or nil
            end)
            if okArrSizeA and tonumber(cA) then
                arrSize = math.max(0, math.floor(tonumber(cA) or 0))
            else
                local okArrSizeB, cB = safeCall(function()
                    return arr.length
                end)
                if okArrSizeB and tonumber(cB) then
                    arrSize = math.max(0, math.floor(tonumber(cB) or 0))
                else
                    arrSize = size
                end
            end
            a.sizeRef = arrSize
            for idx = 0, math.max(0, arrSize - 1) do
                a.iterated = a.iterated + 1
                local okAt, vehicle = readVehiclesAtMode(arr, idx, "raw_index")
                if not okAt then
                    a.errors = a.errors + 1
                end
                captureVehicle(a, vehicle)
            end
        end
        report.attempts[#report.attempts + 1] = a
        considerBest(a)
    end

    best = best or makeAttempt("none", size)
    report.nonNilVehicles = math.max(0, best.nonNil or 0)
    report.iteratedSlots = tonumber(best.iterated) or 0
    report.nilSlots = tonumber(best.nilSlots) or 0
    report.getErrors = tonumber(best.errors) or 0
    report.readModeUsed = tostring(best.attemptName or "none")
    report.indexBaseUsed = (best.attemptName == "iterator") and "iterator" or "array"
    report.sampleSqlIds = best.sampleSqlIds or {}
    report.sampleVehicleIds = best.sampleVehicleIds or {}

    local attempts = {}
    for i = 1, #report.attempts do
        local a = report.attempts[i]
        attempts[#attempts + 1] = string.format(
            "%s@%s=%s/%s e%s",
            tostring(a.attemptName or "none"),
            tostring(a.indexBase or "none"),
            tostring(a.nonNil or 0),
            tostring(a.sizeRef or size),
            tostring(a.errors or 0)
        )
    end
    report.attemptSummary = table.concat(attempts, ",")

    for i = 1, #(best.pairs or {}) do
        local pair = best.pairs[i]
        outMap[pair.sql] = pair.id
    end
    return report
end

local function refreshVehicleSqlIndex()
    NMServerRegistryState.vehicleRuntimeIdBySqlId = NMServerRegistryState.vehicleRuntimeIdBySqlId or {}
    local nowMs = nowRealMs()
    local lastMs = tonumber(NMServerRegistryState.vehicleSqlIndexLastRefreshMs) or 0
    if (nowMs - lastMs) < 1500 then
        return
    end

    local nextMap = {}
    local sourceReports = {}
    local cell = getCell and getCell() or nil
    local world = getWorld and getWorld() or nil
    local worldCell = world and world.getCell and world:getCell() or nil
    local cellClass = readClassName(cell)
    local worldCellClass = readClassName(worldCell)

    local vehiclesA = nil
    local okVehiclesA = false
    if cell then
        okVehiclesA, vehiclesA = safeCall(function()
            return cell:getVehicles()
        end)
    end
    if okVehiclesA and vehiclesA then
        sourceReports[#sourceReports + 1] = collectFromVehiclesSource("cell.getVehicles", vehiclesA, nextMap)
    else
        sourceReports[#sourceReports + 1] = {
            label = "cell.getVehicles",
            sizeReported = 0,
            iteratedSlots = 0,
            nonNilVehicles = 0,
            nilSlots = 0,
            getErrors = okVehiclesA and 0 or 1,
            readModeUsed = "none",
            indexBaseUsed = "none",
            sampleSqlIds = {},
            sampleVehicleIds = {},
            attemptSummary = "none",
            vehiclesClass = "nil"
        }
    end

    local sameCell = (worldCell ~= nil and worldCell == cell)
    if not sameCell and worldCell then
        local okVehiclesB, vehiclesB = safeCall(function()
            return worldCell:getVehicles()
        end)
        if okVehiclesB and vehiclesB then
            sourceReports[#sourceReports + 1] = collectFromVehiclesSource("world.cell.getVehicles", vehiclesB, nextMap)
        else
            sourceReports[#sourceReports + 1] = {
                label = "world.cell.getVehicles",
                sizeReported = 0,
                iteratedSlots = 0,
                nonNilVehicles = 0,
                nilSlots = 0,
                getErrors = okVehiclesB and 0 or 1,
                readModeUsed = "none",
                indexBaseUsed = "none",
                sampleSqlIds = {},
                sampleVehicleIds = {},
                attemptSummary = "none",
                vehiclesClass = "nil"
            }
        end
    else
        sourceReports[#sourceReports + 1] = {
            label = "world.cell.getVehicles",
            sizeReported = 0,
            iteratedSlots = 0,
            nonNilVehicles = 0,
            nilSlots = 0,
            getErrors = 0,
            readModeUsed = "same_as_cell",
            indexBaseUsed = "none",
            sampleSqlIds = {},
            sampleVehicleIds = {},
            attemptSummary = "none",
            vehiclesClass = readClassName(vehiclesA)
        }
    end

    NMServerRegistryState.vehicleRuntimeIdBySqlId = nextMap
    NMServerRegistryState.vehicleSqlIndexLastRefreshMs = nowMs

    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics") and NMCore.shouldLogEvery then
        if NMCore.shouldLogEvery("vehicleDiagnostics.server_sql_index_state", nowMs, 60000) then
            local count = 0
            for _, __ in pairs(nextMap) do
                count = count + 1
            end
            local sourceSummary = {}
            for i = 1, #sourceReports do
                local r = sourceReports[i]
                sourceSummary[#sourceSummary + 1] = string.format(
                    "src%d=%s:%s/%s mode=%s base=%s nil=%s err=%s vclass=%s sql=%s vid=%s attempts=%s",
                    i - 1,
                    tostring(r.label or "unknown"),
                    tostring(r.nonNilVehicles or 0),
                    tostring(r.sizeReported or 0),
                    tostring(r.readModeUsed or "none"),
                    tostring(r.indexBaseUsed or "none"),
                    tostring(r.nilSlots or 0),
                    tostring(r.getErrors or 0),
                    tostring(r.vehiclesClass or "nil"),
                    tostring((r.sampleSqlIds and table.concat(r.sampleSqlIds, ",")) or "none"),
                    tostring((r.sampleVehicleIds and table.concat(r.sampleVehicleIds, ",")) or "none"),
                    tostring(r.attemptSummary or "none")
                )
            end
            NMCore.logChannel(
                "vehicleDiagnostics",
                "server_vehicle_sql_index_state",
                string.format(
                    "entries=%s refreshedMs=%s cellClass=%s worldCellClass=%s %s",
                    tostring(count),
                    tostring(nowMs),
                    tostring(cellClass),
                    tostring(worldCellClass),
                    table.concat(sourceSummary, " ")
                )
            )
        end
    end
end

local function normalizeSourceMode(entry, profile, state)
    local authorityMode = tostring(state and state.authoritativeMode or "off")
    if authorityMode == "vehicle" then
        return "vehicle"
    end
    if authorityMode == "attached" then
        return "attached"
    end
    if authorityMode == "placed" then
        return "placed"
    end
    if authorityMode == "stowed" then
        return "stowed"
    end
    return "off"
end

local function buildPlayerMaps()
    local byId = {}
    local byName = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then
        return byId, byName
    end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p then
            local id = p.getOnlineID and tostring(p:getOnlineID() or "") or ""
            local name = p.getUsername and tostring(p:getUsername() or "") or ""
            if id ~= "" then
                byId[id] = p
            end
            if name ~= "" then
                byName[string.lower(name)] = p
            end
        end
    end
    return byId, byName
end

local function resolvePlayerFromOwner(entry, state, playersById, playersByName)
    local owner = tostring(state and state.sourceOwner or entry and entry.ownerId or entry and entry.ownerOnlineId or entry and entry.ownerUsername or "")
    if owner == "" then
        return nil, owner
    end
    local byId = playersById and playersById[owner] or nil
    if byId then
        return byId, owner
    end
    local byName = playersByName and playersByName[string.lower(owner)] or nil
    if byName then
        return byName, owner
    end
    return nil, owner
end

local function setVehicleIdentityState(entry, uuid, nextState, reason)
    if not entry then
        return
    end
    local currentState = tostring(entry._vehicleIdentityState or "")
    local targetState = tostring(nextState or "")
    if currentState == targetState or targetState == "" then
        entry._vehicleIdentityState = targetState ~= "" and targetState or entry._vehicleIdentityState
        return
    end
    entry._vehicleIdentityState = targetState
    NMRuntimeProbeAdapter.emit(
        "runtimeProbe",
        "runtimeProbe",
        "vehicle_identity_state_transition",
        string.format("uuid=%s from=%s to=%s reason=%s", tostring(uuid), tostring(currentState ~= "" and currentState or "nil"), tostring(targetState), tostring(reason or "none"))
    )
end

local function refreshFromAttached(entry, state, playersById, playersByName)
    local playerObj = nil
    local ownerKey = ""
    playerObj, ownerKey = resolvePlayerFromOwner(entry, state, playersById, playersByName)
    if not playerObj then
        return false, "attached_unresolved", ownerKey
    end
    local sq = playerObj.getSquare and playerObj:getSquare() or nil
    if not sq then
        return false, "attached_unresolved_square", ownerKey
    end
    entry.x = sq:getX()
    entry.y = sq:getY()
    entry.z = sq:getZ()
    entry.ownerOnlineId = playerObj.getOnlineID and tostring(playerObj:getOnlineID() or "") or tostring(entry.ownerOnlineId or "")
    entry.ownerUsername = playerObj.getUsername and tostring(playerObj:getUsername() or "") or tostring(entry.ownerUsername or "")
    return true, "attached_player", ownerKey
end

local function readVehiclePartUuid(vehicle, partId)
    if not vehicle then
        return "", "vehicle_missing"
    end
    local desiredPartId = tostring(partId or "Radio")
    local part = vehicle.getPartById and vehicle:getPartById(desiredPartId) or nil
    if not part then
        return "", "part_missing"
    end
    local md = part.getModData and part:getModData() or nil
    local node = md and md[NMCore.StateKey] or nil
    local partUuid = tostring(node and node.deviceUUID or "")
    if partUuid == "" then
        return "", "part_uuid_missing"
    end
    return partUuid, "ok"
end

local function resolveVehicleIdentity(entry, state, playersById, playersByName)
    local currentUuid = tostring(state and state.deviceUUID or entry and entry.uuid or "")
    local partId = tostring(entry and entry.partId or "Radio")
    local sqlHint = tostring(entry and (entry.vehicleSqlId or entry.vehicleSqlIdHint) or "")
    local vehicleIdHint = tonumber(entry and (entry.vehicleIdHint or entry.vehicleId))
    local cachedVehicle = nil
    if vehicleIdHint and getVehicleById then
        cachedVehicle = getVehicleById(vehicleIdHint)
    end
    local ownerPlayer, ownerKey = resolvePlayerFromOwner(entry, state, playersById, playersByName)
    local ownerVehicle = ownerPlayer and ownerPlayer.getVehicle and ownerPlayer:getVehicle() or nil
    local ownerVehicleId = ownerVehicle and ownerVehicle.getId and tostring(ownerVehicle:getId() or "") or ""
    local ownerVehicleSqlId = NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(ownerVehicle) or ""

    local result = {
        resolved = false,
        vehicle = nil,
        vehicleId = "",
        vehicleSqlId = "",
        partId = partId,
        matchReason = "vehicle_unresolved",
        resolvedBy = "none",
        sourceGenerationSeen = tonumber(state and state.sourceGeneration) or tonumber(entry and entry.sourceEpoch) or 0,
        ownerKey = tostring(ownerKey or ""),
        ownerVehicleId = ownerVehicleId ~= "" and ownerVehicleId or "nil",
        ownerVehicleSqlId = ownerVehicleSqlId ~= "" and ownerVehicleSqlId or "nil",
        ownerVehicleSeen = ownerVehicle ~= nil,
        preScanReason = "sql_index",
        reasonStage = "sql_anchor_missing",
        sourceMatrixSummary = "",
        sqlHint = tostring(sqlHint ~= "" and sqlHint or "nil"),
        poolSource = "sql_index",
        totalReported = 0,
        nonNilVehicles = 0,
        indexBaseUsed = "none",
        indexBaseTried = "none",
        iteratedSlots = 0,
        nilSlots = 0,
        getErrors = 0
    }

    if sqlHint == "" then
        result.matchReason = "sql_anchor_missing"
        result.reasonStage = "sql_anchor_missing"
        return result
    end

    local indexMap = NMServerRegistryState and NMServerRegistryState.vehicleRuntimeIdBySqlId or nil
    local runtimeId = tostring(indexMap and indexMap[tostring(sqlHint)] or "")
    if runtimeId == "" then
        result.matchReason = "sql_anchor_runtime_unavailable"
        result.reasonStage = "sql_anchor_runtime_unavailable"
        result.anchorEvidence = "sql=" .. tostring(sqlHint) .. " runtimeId=nil"
        return result
    end

    local resolvedVehicle = nil
    if getVehicleById then
        resolvedVehicle = getVehicleById(tonumber(runtimeId))
    end
    if not resolvedVehicle then
        result.matchReason = "sql_anchor_runtime_unavailable"
        result.reasonStage = "sql_anchor_runtime_unavailable"
        result.anchorEvidence = "sql=" .. tostring(sqlHint) .. " runtimeId=" .. tostring(runtimeId) .. " vehicle=nil"
        return result
    end

    local observedSql = NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(resolvedVehicle) or ""
    if tostring(observedSql) ~= tostring(sqlHint) then
        result.matchReason = "sql_anchor_runtime_unavailable"
        result.reasonStage = "sql_anchor_runtime_unavailable"
        result.anchorEvidence = "sql=" .. tostring(sqlHint) .. " runtimeId=" .. tostring(runtimeId) .. " observedSql=" .. tostring(observedSql ~= "" and observedSql or "nil")
        return result
    end

    local part = resolvedVehicle.getPartById and resolvedVehicle:getPartById(partId) or nil
    if not part then
        result.matchReason = "sql_anchor_part_missing"
        result.reasonStage = "sql_anchor_part_missing"
        result.anchorEvidence = "sql=" .. tostring(sqlHint) .. " partId=" .. tostring(partId)
        return result
    end

    local partUuid, partUuidState = readVehiclePartUuid(resolvedVehicle, partId)
    if partUuidState ~= "ok" or partUuid ~= currentUuid then
        result.matchReason = "sql_anchor_uuid_mismatch"
        result.reasonStage = "sql_anchor_uuid_mismatch"
        result.anchorEvidence = "sql=" .. tostring(sqlHint) .. " observedUuid=" .. tostring(partUuid ~= "" and partUuid or "nil")
        result.part = part
        return result
    end

    result.resolved = true
    result.vehicle = resolvedVehicle
    result.part = part
    result.vehicleId = tostring(resolvedVehicle:getId() or "")
    result.vehicleSqlId = tostring(observedSql or "")
    result.resolvedBy = "sql_anchor"
    result.matchReason = "resolved_sql_anchor"
    result.reasonStage = "sql_anchor_resolved"
    result.anchorEvidence = "sql=" .. tostring(sqlHint) .. " runtimeId=" .. tostring(runtimeId)
    return result
end

local function logVehicleResolveAttempt(uuid, entry, result)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics")) then
        return
    end
    if not result then
        return
    end
    local signature = table.concat({
        tostring(result.resolved == true),
        tostring(result.resolvedBy or ""),
        tostring(result.vehicleId or ""),
        tostring(result.reasonStage or "")
    }, "|")
    if entry and entry._vehicleResolveAttemptSignature == signature then
        return
    end
    if entry then
        entry._vehicleResolveAttemptSignature = signature
    end
    NMCore.logChannel(
        "vehicleDiagnostics",
        "server_vehicle_resolve_attempt",
        string.format(
            "uuid=%s resolved=%s path=%s reason=%s reasonStage=%s preScan=%s cachedVehicleId=%s resolvedVehicleId=%s owner=%s ownerVehicleId=%s cachedVehicleSqlId=%s resolvedVehicleSqlId=%s ownerVehicleSqlId=%s authorityVehicleSqlId=%s cachedPartUuid=%s ownerPartUuid=%s poolSource=%s totalReported=%s nonNilVehicles=%s indexBaseUsed=%s indexBaseTried=%s iteratedSlots=%s nilSlots=%s getErrors=%s matrix=%s anchor=%s",
            tostring(uuid),
            tostring(result.resolved == true),
            tostring(result.resolvedBy or "none"),
            tostring(result.matchReason or "unknown"),
            tostring(result.reasonStage or "none"),
            tostring(result.preScanReason or "none"),
            tostring(entry and entry.vehicleId or ""),
            tostring(result.vehicleId or ""),
            tostring(result.ownerKey or ""),
            tostring(result.ownerVehicleId or "nil"),
            tostring(result.cachedVehicleSqlId or entry and entry.vehicleSqlId or ""),
            tostring(result.vehicleSqlId or ""),
            tostring(result.ownerVehicleSqlId or "nil"),
            tostring(result.authorityVehicleSqlId or ""),
            tostring(result.cachedPartUuid or ""),
            tostring(result.ownerPartUuid or ""),
            tostring(result.poolSource or "none"),
            tostring(result.totalReported or 0),
            tostring(result.nonNilVehicles or 0),
            tostring(result.indexBaseUsed or "none"),
            tostring(result.indexBaseTried or "none"),
            tostring(result.iteratedSlots or 0),
            tostring(result.nilSlots or 0),
            tostring(result.getErrors or 0),
            tostring(result.sourceMatrixSummary or ""),
            tostring(result.anchorEvidence or "anchor=none")
        )
    )
end

local function formatCoord(value)
    local n = tonumber(value)
    if not n then
        return "nil"
    end
    return string.format("%.2f", n)
end

local function resolveVehicleSnapshotFields(vehicle)
    local vehicleId = NMVehicleHelpers and NMVehicleHelpers.getVehicleIdString and NMVehicleHelpers.getVehicleIdString(vehicle) or ""
    local vehicleSqlId = NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(vehicle) or ""
    local scriptName = NMVehicleHelpers and NMVehicleHelpers.getVehicleScriptName and NMVehicleHelpers.getVehicleScriptName(vehicle) or ""
    local x = tonumber(vehicle and vehicle.getX and vehicle:getX() or nil)
    local y = tonumber(vehicle and vehicle.getY and vehicle:getY() or nil)
    local z = tonumber(vehicle and vehicle.getZ and vehicle:getZ() or nil)
    return vehicleId, vehicleSqlId, scriptName, x, y, z
end

local function logVehicleIdentitySnapshot(entry, uuid, stage, result)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics")) then
        return
    end
    if not entry then
        return
    end
    local now = nowRealMs()
    local resolvedVehicle = result and result.vehicle or nil
    local resolvedVehicleId, resolvedVehicleSqlId, resolvedScript, resolvedX, resolvedY, resolvedZ = resolveVehicleSnapshotFields(resolvedVehicle)

    local cachedVehicle = nil
    local cachedIdHint = tonumber(entry and (entry.vehicleIdHint or entry.vehicleId) or nil)
    if cachedIdHint and getVehicleById then
        cachedVehicle = getVehicleById(cachedIdHint)
    end
    local cachedVehicleId, cachedVehicleSqlId, cachedScript, cachedX, cachedY, cachedZ = resolveVehicleSnapshotFields(cachedVehicle)

    local sourceGen = tonumber(result and result.sourceGenerationSeen) or tonumber(entry.sourceGeneration) or tonumber(entry.sourceEpoch) or 0
    local signature = table.concat({
        tostring(result and result.resolved == true),
        tostring(result and result.reasonStage or result and result.matchReason or "none"),
        tostring(resolvedVehicleId or ""),
        tostring(resolvedVehicleSqlId or ""),
        tostring(resolvedScript or ""),
        tostring(formatCoord(resolvedX)),
        tostring(formatCoord(resolvedY)),
        tostring(formatCoord(resolvedZ)),
        tostring(cachedVehicleId or ""),
        tostring(cachedVehicleSqlId or ""),
        tostring(cachedScript or ""),
        tostring(formatCoord(cachedX)),
        tostring(formatCoord(cachedY)),
        tostring(formatCoord(cachedZ)),
        tostring(result and result.matchReason or "none")
    }, "|")

    local previousSig = tostring(entry._vehicleIdentitySnapshotSig or "")
    local previousMs = tonumber(entry._vehicleIdentitySnapshotMs) or 0
    if signature == previousSig and (now - previousMs) < 15000 then
        return
    end
    entry._vehicleIdentitySnapshotSig = signature
    entry._vehicleIdentitySnapshotMs = now

    NMCore.logChannel(
        "vehicleDiagnostics",
        "vehicle_identity_snapshot",
        string.format(
            "uuid=%s stage=%s resolved=%s reasonStage=%s reason=%s resolvedVehicleId=%s resolvedVehicleSqlId=%s resolvedScript=%s resolvedX=%s resolvedY=%s resolvedZ=%s cachedVehicleId=%s cachedVehicleSqlId=%s cachedScript=%s cachedX=%s cachedY=%s cachedZ=%s sourceGen=%s",
            tostring(uuid or ""),
            tostring(stage or ""),
            tostring(result and result.resolved == true),
            tostring(result and result.reasonStage or "none"),
            tostring(result and result.matchReason or "none"),
            tostring(resolvedVehicleId ~= "" and resolvedVehicleId or "nil"),
            tostring(resolvedVehicleSqlId ~= "" and resolvedVehicleSqlId or "nil"),
            tostring(resolvedScript ~= "" and resolvedScript or "nil"),
            formatCoord(resolvedX),
            formatCoord(resolvedY),
            formatCoord(resolvedZ),
            tostring(cachedVehicleId ~= "" and cachedVehicleId or "nil"),
            tostring(cachedVehicleSqlId ~= "" and cachedVehicleSqlId or "nil"),
            tostring(cachedScript ~= "" and cachedScript or "nil"),
            formatCoord(cachedX),
            formatCoord(cachedY),
            formatCoord(cachedZ),
            tostring(sourceGen)
        )
    )
end

local function refreshFromVehicle(entry, state, playersById, playersByName)
    local result = resolveVehicleIdentity(entry, state, playersById, playersByName)
    SourceRefreshDiagnostics.logVehicleIdentitySnapshot(entry, tostring(entry and entry.uuid or state and state.deviceUUID or ""), "refresh_attempt", result)
    local vehicle = result and result.vehicle or nil
    if not vehicle then
        local unresolvedReason = tostring(result and result.reasonStage or result and result.matchReason or "vehicle_unresolved")
        return false, "vehicle_unresolved_" .. unresolvedReason, tostring(entry and entry.vehicleId or ""), result
    end

    local oldVehicleId = tostring(entry and (entry.vehicleIdHint or entry.vehicleId) or "")
    local newVehicleId = tostring(vehicle:getId() or "")
    local newVehicleSqlId = NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(vehicle) or ""
    local rebind = oldVehicleId ~= "" and newVehicleId ~= "" and oldVehicleId ~= newVehicleId
    entry.sourceRebind = rebind == true
    if newVehicleId ~= "" then
        -- Only mutate identity on strict UUID+part resolution success.
        entry.vehicleId = newVehicleId
        entry.vehicleIdHint = newVehicleId
        entry.vehicleSqlId = tostring(newVehicleSqlId or entry.vehicleSqlId or "")
        entry.vehicleSqlIdHint = tostring(newVehicleSqlId or entry.vehicleSqlIdHint or entry.vehicleSqlId or "")
    end
    entry.x = tonumber(vehicle:getX()) or entry.x
    entry.y = tonumber(vehicle:getY()) or entry.y
    entry.z = tonumber(vehicle:getZ()) or entry.z
    entry.windowsOpen = NMVehicleHelpers.vehicleWindowsOpen(vehicle)
    SourceRefreshDiagnostics.logVehicleIdentitySnapshot(entry, tostring(entry and entry.uuid or state and state.deviceUUID or ""), "refresh_resolved", result)
    if rebind then
        return true, "vehicle_rebind", tostring(newVehicleId), result
    end
    return true, "vehicle_live", tostring(newVehicleId), result
end

local function broadcastEntryUpdate(entry, op, rebindReason)
    if not (entry and NMServerRegistryBroadcast and NMServerRegistryBroadcast.broadcastEntry) then
        return
    end
    local function recipients(applyFn)
        local players = getOnlinePlayers and getOnlinePlayers() or nil
        if not players then
            return
        end
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p then
                applyFn(p)
            end
        end
    end
    local previousReason = entry.rebindReason
    if rebindReason ~= nil then
        entry.rebindReason = tostring(rebindReason)
    end
    NMServerRegistryBroadcast.broadcastEntry(
        NMServerRegistryState.worldRegistry,
        tostring(entry.uuid or ""),
        nil,
        entry.stateSnapshot,
        tostring(op or "upsert"),
        recipients
    )
    entry.rebindReason = previousReason
end

local function refreshFromStateSnapshot(entry, state)
    local sx = asNumber(state and state.sourceX)
    local sy = asNumber(state and state.sourceY)
    local sz = asNumber(state and state.sourceZ)
    if sx == nil or sy == nil or sz == nil then
        return false, "snapshot_missing", ""
    end
    entry.x = sx
    entry.y = sy
    entry.z = sz
    return true, "snapshot", ""
end

local function parseRefreshSignature(signature)
    local mode, resolved, xq, yq, zq = string.match(tostring(signature or ""), "([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)")
    return mode, resolved, tonumber(xq), tonumber(yq), tonumber(zq)
end

local function shouldLogRefreshChange(uuid, signature)
    local nowMs = nowRealMs()
    local minChangeLogMs = 3000
    local heartbeatMs = 30000
    NMServerRegistryState.sourceRefreshSignature = NMServerRegistryState.sourceRefreshSignature or {}
    NMServerRegistryState.sourceRefreshLastLogMs = NMServerRegistryState.sourceRefreshLastLogMs or {}

    local prev = NMServerRegistryState.sourceRefreshSignature[uuid]
    local prevMs = tonumber(NMServerRegistryState.sourceRefreshLastLogMs[uuid]) or 0
    if prev == nil then
        NMServerRegistryState.sourceRefreshSignature[uuid] = signature
        NMServerRegistryState.sourceRefreshLastLogMs[uuid] = nowMs
        return true
    end
    local modePrev, resolvedPrev = parseRefreshSignature(prev)
    local modeNext, resolvedNext = parseRefreshSignature(signature)
    local modeChanged = tostring(modePrev) ~= tostring(modeNext) or tostring(resolvedPrev) ~= tostring(resolvedNext)
    if modeChanged then
        NMServerRegistryState.sourceRefreshSignature[uuid] = signature
        NMServerRegistryState.sourceRefreshLastLogMs[uuid] = nowMs
        return true
    end
    local changed = prev ~= signature
    local elapsed = nowMs - prevMs
    if changed and elapsed >= minChangeLogMs then
        NMServerRegistryState.sourceRefreshSignature[uuid] = signature
        NMServerRegistryState.sourceRefreshLastLogMs[uuid] = nowMs
        return true
    end
    if elapsed >= heartbeatMs then
        NMServerRegistryState.sourceRefreshSignature[uuid] = signature
        NMServerRegistryState.sourceRefreshLastLogMs[uuid] = nowMs
        return true
    end
    if changed then
        NMServerRegistryState.sourceRefreshSignature[uuid] = signature
    end
    return false
end

local function logRefresh(uuid, mode, oldX, oldY, oldZ, newX, newY, newZ, resolvedKind)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics")) then
        return
    end
    local signature = table.concat({
        tostring(mode or ""),
        tostring(resolvedKind or ""),
        string.format("%.1f", tonumber(newX) or 0),
        string.format("%.1f", tonumber(newY) or 0),
        string.format("%.1f", tonumber(newZ) or 0)
    }, "|")
    if not shouldLogRefreshChange(uuid, signature) then
        return
    end
    NMCore.logChannel(
        "vehicleDiagnostics",
        "server_source_refresh",
        string.format(
            "uuid=%s mode=%s resolved=%s old=%.2f,%.2f,%.2f new=%.2f,%.2f,%.2f",
            tostring(uuid),
            tostring(mode),
            tostring(resolvedKind),
            tonumber(oldX) or 0,
            tonumber(oldY) or 0,
            tonumber(oldZ) or 0,
            tonumber(newX) or 0,
            tonumber(newY) or 0,
            tonumber(newZ) or 0
        )
    )
end

local function logUnresolved(uuid, mode, reason, key)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics")) then
        return
    end
    if NMCore.shouldLogEvery and not NMCore.shouldLogEvery("vehicleDiagnostics.source_refresh_unresolved." .. tostring(uuid), nowRealMs(), 15000) then
        return
    end
    NMCore.logChannel(
        "vehicleDiagnostics",
        "server_source_refresh_unresolved",
        string.format("uuid=%s mode=%s reason=%s key=%s", tostring(uuid), tostring(mode), tostring(reason), tostring(key or ""))
    )
end

local function logInvalidCoordinates(uuid, mode)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics")) then
        return
    end
    NMCore.logChannel(
        "vehicleDiagnostics",
        "server_source_refresh_invalid",
        string.format("uuid=%s mode=%s reason=world_active_invalid_coordinates", tostring(uuid), tostring(mode))
    )
end

local function logVehicleRebindBroadcast(uuid, reason, entry)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics")) then
        return
    end
    NMCore.logChannel(
        "vehicleDiagnostics",
        "server_vehicle_rebind_broadcast",
        string.format(
            "uuid=%s reason=%s vehicleId=%s partId=%s sourceMode=%s sourceEpoch=%s",
            tostring(uuid),
            tostring(reason),
            tostring(entry and entry.vehicleId or ""),
            tostring(entry and entry.partId or "Radio"),
            tostring(entry and entry.sourceMode or "vehicle"),
            tostring(entry and entry.sourceEpoch or 0)
        )
    )
end

function NMServerSourceRefreshTick.onTick()
    if not NMCore.isMPServerAuthority() then
        return
    end

    refreshVehicleSqlIndex()
    local playersById, playersByName = buildPlayerMaps()
    for uuid, entry in pairs(NMServerRegistryState.worldRegistry) do
        local state = entry and entry.stateSnapshot or nil
        local profileType = entry and entry.profileType or nil
        local profile = NMDeviceProfiles and profileType and NMDeviceProfiles.getForFullType(profileType) or nil
        if state and profile then
            local oldX = tonumber(entry.x) or 0
            local oldY = tonumber(entry.y) or 0
            local oldZ = tonumber(entry.z) or 0
            local prevVehicleResolved = entry._vehicleResolved == true

            local sourceMode = normalizeSourceMode(entry, profile, state)
            entry.sourceMode = sourceMode
            entry.sourceEpoch = math.max(tonumber(entry.sourceEpoch) or 0, tonumber(state.sourceGeneration) or 0)
            entry.sourceGeneration = entry.sourceEpoch
            entry.ownerId = tostring(state and state.sourceOwner or entry.ownerId or "")
            entry.vehicleIdHint = tostring(entry.vehicleIdHint or entry.vehicleId or "")

            local resolved = false
            local resolvedKind = "cached"
            local key = ""
            local resolvedMeta = nil

            if sourceMode == "attached" then
                resolved, resolvedKind, key = refreshFromAttached(entry, state, playersById, playersByName)
            elseif sourceMode == "vehicle" then
                resolved, resolvedKind, key, resolvedMeta = refreshFromVehicle(entry, state, playersById, playersByName)
                SourceRefreshDiagnostics.logVehicleResolveAttempt(uuid, entry, resolvedMeta)
            elseif sourceMode == "stowed" then
                resolved, resolvedKind, key = refreshFromStateSnapshot(entry, state)
            end

            if not resolved and (sourceMode == "attached" or sourceMode == "vehicle") then
                entry._vehicleResolved = false
                if sourceMode == "vehicle" then
                    entry.sourceRebind = false
                    setVehicleIdentityState(entry, uuid, "DETACHED_CONTINUITY", resolvedKind)
                    entry._vehicleContinuityMode = "DETACHED_CONTINUITY"
                end
                SourceRefreshDiagnostics.logUnresolved(uuid, sourceMode, resolvedKind, key)
                if sourceMode == "vehicle" then
                    local enteringUnresolved = entry._vehicleUnresolvedSinceMs == nil
                    entry._vehicleUnresolvedSinceMs = tonumber(entry._vehicleUnresolvedSinceMs) or nowRealMs()
                    if enteringUnresolved and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                        NMCore.logChannel(
                            "runtimeProbe",
                            "server_vehicle_unresolved_enter",
                            string.format("uuid=%s vehicleId=%s", tostring(uuid), tostring(entry and entry.vehicleId or ""))
                        )
                    end
                end
            else
                local hadUnresolved = entry._vehicleUnresolvedSinceMs ~= nil
                entry._vehicleUnresolvedSinceMs = nil
                if sourceMode == "vehicle" then
                    entry._vehicleResolved = true
                    setVehicleIdentityState(entry, uuid, "LIVE_RESOLVED", resolvedKind)
                    if entry._vehicleContinuityMode ~= "LIVE_RESOLVED" and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                        NMCore.logChannel("runtimeProbe", "vehicle_continuity_mode_exit", string.format("uuid=%s mode=%s reason=resolved", tostring(uuid), tostring(entry._vehicleContinuityMode or "DETACHED_CONTINUITY")))
                    end
                    entry._vehicleContinuityMode = "LIVE_RESOLVED"
                    local rebindTransition = (resolvedKind == "vehicle_rebind")
                    local recoveredTransition = hadUnresolved and (prevVehicleResolved == false)
                    if hadUnresolved and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                        NMCore.logChannel(
                            "runtimeProbe",
                            "server_vehicle_unresolved_recovered",
                            string.format("uuid=%s vehicleId=%s", tostring(uuid), tostring(entry and entry.vehicleId or ""))
                        )
                    end
                    entry._vehicleLastResolvedMs = nowRealMs()
                    if rebindTransition or recoveredTransition then
                        -- Promote vehicle identity recovery/rebind as a strictly newer authority update.
                        local previousGen = math.max(0, tonumber(state.sourceGeneration) or 0)
                        state.sourceGeneration = previousGen + 1
                        state.sourceKind = "vehicle"
                        state.sourceX = tonumber(entry.x) or state.sourceX
                        state.sourceY = tonumber(entry.y) or state.sourceY
                        state.sourceZ = tonumber(entry.z) or state.sourceZ
                        entry.sourceEpoch = math.max(tonumber(entry.sourceEpoch) or 0, tonumber(state.sourceGeneration) or 0)
                        entry.sourceGeneration = entry.sourceEpoch
                        entry.stateSnapshot = NMDeviceState.export(state)
                        local transitionReason = rebindTransition and "vehicle_rebind" or "unresolved_recovered"
                        broadcastEntryUpdate(entry, "upsert", transitionReason)
                        SourceRefreshDiagnostics.logVehicleRebindBroadcast(
                            uuid,
                            transitionReason,
                            entry
                        )
                    end
                end
            end

            local worldActive = NMRegistryPolicy.shouldKeepWorldSourceState(state)
            if worldActive and sourceMode ~= "off" then
                local x = asNumber(entry.x)
                local y = asNumber(entry.y)
                local z = asNumber(entry.z)
                if x == nil or y == nil or z == nil then
                    SourceRefreshDiagnostics.logInvalidCoordinates(uuid, sourceMode)
                end
            end

            SourceRefreshDiagnostics.logRefresh(uuid, sourceMode, oldX, oldY, oldZ, entry.x, entry.y, entry.z, resolvedKind)
            NMServerRegistryState.worldRegistry[uuid] = entry
        end
    end
end

