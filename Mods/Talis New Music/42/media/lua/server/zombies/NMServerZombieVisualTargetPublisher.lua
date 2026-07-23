NMServerZombieVisualTargetPublisher = NMServerZombieVisualTargetPublisher or {}
require "zombies/NMZombieDeviceVariantCatalog"
NMServerZombieVisualTargetPublisher._tick = NMServerZombieVisualTargetPublisher._tick or 0
NMServerZombieVisualTargetPublisher._playerState = NMServerZombieVisualTargetPublisher._playerState or {}
NMServerZombieVisualTargetPublisher._diag = NMServerZombieVisualTargetPublisher._diag or {
    publishCalls = 0,
    snapshotsSent = 0,
    targetCandidates = 0,
    targetPublished = 0
}

local function shouldLog()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("zombieDiagnostics") == true
end

local function logSummary(tag, detail)
    if not shouldLog() then
        return
    end
    print("[NewMusic] [ZombieProof] " .. tostring(tag or "") .. " " .. tostring(detail or ""))
end

local function canPublish()
    if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() == true then
        return false
    end
    if not (NMCore and NMCore.isMultiplayerMode and NMCore.isMultiplayerMode() == true) then
        return false
    end
    if isClient and isClient() == true then
        return false
    end
    if not (sendServerCommand and NMCore and NMCore.NetModule) then
        return false
    end
    return true
end

local function isAliveZombie(zombie)
    if not (zombie and instanceof and instanceof(zombie, "IsoZombie")) then
        return false
    end
    if zombie.isDead and zombie:isDead() then
        return false
    end
    if zombie.isOnDeathDone and zombie:isOnDeathDone() then
        return false
    end
    return true
end

local function getPlayerId(player)
    if player and player.getOnlineID then
        return tostring(player:getOnlineID() or "")
    end
    return tostring(player or "")
end

local function collectPlayers()
    local out = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not (players and players.size) then
        return out
    end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            out[#out + 1] = player
        end
    end
    return out
end

local function makeZombieDistanceCheck(player)
    local square = player and player.getSquare and player:getSquare() or nil
    if not square then
        return nil
    end
    local px = (tonumber(square:getX()) or 0) + 0.5
    local py = (tonumber(square:getY()) or 0) + 0.5
    local pz = tonumber(square:getZ()) or 0
    local radiusSq = (tonumber(NMZombieVisualTargetContract and NMZombieVisualTargetContract.NearbyRadius) or 30) ^ 2
    return function(zombie)
        if not (zombie and zombie.getX and zombie.getY) then
            return false
        end
        local zz = tonumber(zombie.getZ and zombie:getZ() or 0) or 0
        if math.abs(zz - pz) > 2 then
            return false
        end
        local dx = px - (tonumber(zombie:getX()) or 0)
        local dy = py - (tonumber(zombie:getY()) or 0)
        return ((dx * dx) + (dy * dy)) <= radiusSq
    end
end

local function collectTargetRecordsForPlayer(player)
    local allowZombie = makeZombieDistanceCheck(player)
    local result = {
        records = {},
        targetCandidates = 0,
        targetPublished = 0
    }
    if not allowZombie then
        return result
    end
    local zombies = getCell() and getCell():getZombieList() or nil
    if not (zombies and zombies.size) then
        return result
    end
    local seen = {}
    local maxTargets = tonumber(NMZombieVisualTargetContract and NMZombieVisualTargetContract.MaxTargetsPerPlayer) or 96
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if isAliveZombie(zombie) and allowZombie(zombie) then
            local zombieId = NMZombieVisualTargetContract.getZombieId(zombie)
            if not seen[zombieId] then
                seen[zombieId] = true
                result.targetCandidates = result.targetCandidates + 1
                local activeStrategy = NMZombieLiveStrategy and NMZombieLiveStrategy.getLiveVisualStrategy and NMZombieLiveStrategy.getLiveVisualStrategy() or "mp_assignment_flow"
                local selection = NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.getOrAssignZombieSelection and NMZombieVisualTargetLedger.getOrAssignZombieSelection(zombie, activeStrategy) or nil
                if selection
                    and NMZombieDeviceVariantCatalog
                    and NMZombieDeviceVariantCatalog.shouldRealizeSelection
                    and NMZombieDeviceVariantCatalog.shouldRealizeSelection(selection) == true then
                    local spec = NMZombieDeviceVariantCatalog.resolveRealization and NMZombieDeviceVariantCatalog.resolveRealization(selection, zombieId) or nil
                    if spec then
                        result.targetPublished = result.targetPublished + 1
                        result.records[#result.records + 1] = {
                            zombieId = zombieId,
                            variantId = tostring(spec.variantId or ""),
                            fullType = tostring(spec.fullType or ""),
                            attachmentLocation = tostring(spec.attachmentLocation or ""),
                            modelAttachmentName = tostring(spec.modelAttachmentName or "")
                        }
                    end
                    if #result.records >= maxTargets then
                        break
                    end
                end
            end
        end
    end
    table.sort(result.records, function(a, b)
        return tostring(a and a.zombieId or "") < tostring(b and b.zombieId or "")
    end)
    return result
end

local function publishSnapshot(player, state, snapshot)
    state.revision = (tonumber(state.revision) or 0) + 1
    state.lastSentTick = tonumber(NMServerZombieVisualTargetPublisher._tick) or 0
    local targetIds = {}
    for i = 1, #(snapshot.records or {}) do
        targetIds[#targetIds + 1] = tostring(snapshot.records[i] and snapshot.records[i].zombieId or "")
    end
    sendServerCommand(player, NMCore.NetModule, NMZombieVisualTargetContract.NetCommand, {
        revision = state.revision,
        ttlTicks = tonumber(NMZombieVisualTargetContract.ClientCacheTtlTicks) or 0,
        targetIds = targetIds,
        targetRecords = snapshot.records,
        targetCandidates = snapshot.targetCandidates,
        targetPublished = snapshot.targetPublished
    })
    NMServerZombieVisualTargetPublisher._diag.snapshotsSent = (NMServerZombieVisualTargetPublisher._diag.snapshotsSent or 0) + 1
end

function NMServerZombieVisualTargetPublisher.onTick()
    if not canPublish() then
        return
    end
    NMServerZombieVisualTargetPublisher._tick = (tonumber(NMServerZombieVisualTargetPublisher._tick) or 0) + 1
    if (NMServerZombieVisualTargetPublisher._tick % (tonumber(NMZombieVisualTargetContract.PublishIntervalTicks) or 90)) ~= 0 then
        return
    end
    local players = collectPlayers()
    local activePlayers = {}
    NMServerZombieVisualTargetPublisher._diag.publishCalls = (NMServerZombieVisualTargetPublisher._diag.publishCalls or 0) + 1
    for i = 1, #players do
        local player = players[i]
        local playerId = getPlayerId(player)
        if playerId ~= "" then
            activePlayers[playerId] = true
            local state = NMServerZombieVisualTargetPublisher._playerState[playerId] or { revision = 0, signature = nil, lastSentTick = 0 }
            local snapshot = collectTargetRecordsForPlayer(player)
            local signature = NMZombieVisualTargetContract and NMZombieVisualTargetContract.getRecordSignature and NMZombieVisualTargetContract.getRecordSignature(snapshot.records) or ""
            NMServerZombieVisualTargetPublisher._diag.targetCandidates = (NMServerZombieVisualTargetPublisher._diag.targetCandidates or 0) + snapshot.targetCandidates
            NMServerZombieVisualTargetPublisher._diag.targetPublished = (NMServerZombieVisualTargetPublisher._diag.targetPublished or 0) + snapshot.targetPublished
            local republishInterval = tonumber(NMZombieVisualTargetContract.RepublishIntervalTicks) or 180
            local ticksSinceSend = (tonumber(NMServerZombieVisualTargetPublisher._tick) or 0) - (tonumber(state.lastSentTick) or 0)
            if signature ~= state.signature or ticksSinceSend >= republishInterval then
                publishSnapshot(player, state, snapshot)
                state.signature = signature
            end
            state.lastSeenTick = NMServerZombieVisualTargetPublisher._tick
            NMServerZombieVisualTargetPublisher._playerState[playerId] = state
        end
    end
    for playerId, _ in pairs(NMServerZombieVisualTargetPublisher._playerState) do
        if activePlayers[playerId] ~= true then
            NMServerZombieVisualTargetPublisher._playerState[playerId] = nil
        end
    end
    logSummary(
        "target_publish",
        string.format(
            "players=%s publishCalls=%s snapshotsSent=%s candidates=%s published=%s",
            tostring(#players),
            tostring(NMServerZombieVisualTargetPublisher._diag.publishCalls or 0),
            tostring(NMServerZombieVisualTargetPublisher._diag.snapshotsSent or 0),
            tostring(NMServerZombieVisualTargetPublisher._diag.targetCandidates or 0),
            tostring(NMServerZombieVisualTargetPublisher._diag.targetPublished or 0)
        )
    )
    if NMServerZombieVisualTargetLedger and NMServerZombieVisualTargetLedger.logDiag then
        NMServerZombieVisualTargetLedger.logDiag("target_ledger")
    end
end

return NMServerZombieVisualTargetPublisher
