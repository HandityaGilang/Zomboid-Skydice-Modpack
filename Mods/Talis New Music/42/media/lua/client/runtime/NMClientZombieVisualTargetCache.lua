NMClientZombieVisualTargetCache = NMClientZombieVisualTargetCache or {}
NMClientZombieVisualTargetCache._tick = NMClientZombieVisualTargetCache._tick or 0
NMClientZombieVisualTargetCache._revision = NMClientZombieVisualTargetCache._revision or 0
NMClientZombieVisualTargetCache._ttlTicks = NMClientZombieVisualTargetCache._ttlTicks or 0
NMClientZombieVisualTargetCache._receivedTick = NMClientZombieVisualTargetCache._receivedTick or 0
NMClientZombieVisualTargetCache._hasSnapshot = NMClientZombieVisualTargetCache._hasSnapshot or false
NMClientZombieVisualTargetCache._targetCount = NMClientZombieVisualTargetCache._targetCount or 0
NMClientZombieVisualTargetCache._staleLoggedRevision = NMClientZombieVisualTargetCache._staleLoggedRevision or 0
NMClientZombieVisualTargetCache._staleLoggedAge = NMClientZombieVisualTargetCache._staleLoggedAge or 0
NMClientZombieVisualTargetCache._targets = NMClientZombieVisualTargetCache._targets or {}

local function shouldLog()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("zombieDiagnostics") == true
end

local function logSummary(tag, detail)
    if not shouldLog() then
        return
    end
    print("[NewMusic] [ZombieProof] " .. tostring(tag or "") .. " " .. tostring(detail or ""))
end

local function clearTargets()
    NMClientZombieVisualTargetCache._targets = {}
    NMClientZombieVisualTargetCache._targetCount = 0
end

local function isMPClientRuntime()
    return NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() == true
end

local function isSPLocalRuntime()
    return NMCore and NMCore.getRuntimeAuthorityMode and NMCore.getRuntimeAuthorityMode() == "sp_local"
end

local function getStampedProofModData(zombie)
    local key = NMZombieVisualTargetContract and NMZombieVisualTargetContract.ModDataKey or "nmZombieWalkmanProof"
    local root = zombie and zombie.getModData and zombie:getModData() or nil
    local md = root and root[key] or nil
    if type(md) ~= "table" then
        return nil
    end
    return md
end

local function getSPStampedDecision(zombie)
    if not isSPLocalRuntime() then
        return nil
    end
    local md = getStampedProofModData(zombie)
    if type(md) ~= "table" then
        return nil
    end
    local wantedSource = tostring(NMZombieVisualTargetContract and NMZombieVisualTargetContract.SelectionSource or "server_ledger")
    local selectionSource = tostring(md.selectionSource or "")
    if selectionSource ~= wantedSource then
        return nil
    end
    local stampedZombieId = tostring(md.selectionZombieId or "")
    local zombieId = tostring(NMZombieVisualTargetContract and NMZombieVisualTargetContract.getZombieId and NMZombieVisualTargetContract.getZombieId(zombie) or zombie or "")
    if stampedZombieId == "" or zombieId == "" or stampedZombieId ~= zombieId then
        return nil
    end
    local status = tostring(md.status or "")
    local selected = status == "attached"
    return {
        authoritative = true,
        selected = selected,
        state = selected and "selected" or "excluded",
        source = "sp_stamp",
        zombieId = zombieId,
        variantId = tostring(md.variantId or ""),
        fullType = tostring(md.fullType or ""),
        attachmentLocation = tostring(md.attachmentLocation or ""),
        modelAttachmentName = tostring(md.modelAttachmentName or "")
    }
end

function NMClientZombieVisualTargetCache.onServerCommand(command, args)
    if tostring(command or "") ~= tostring(NMZombieVisualTargetContract and NMZombieVisualTargetContract.NetCommand or "") then
        return false
    end
    local revision = tonumber(args and args.revision) or 0
    if revision < (tonumber(NMClientZombieVisualTargetCache._revision) or 0) then
        return true
    end
    NMClientZombieVisualTargetCache._revision = revision
    NMClientZombieVisualTargetCache._ttlTicks = tonumber(args and args.ttlTicks) or tonumber(NMZombieVisualTargetContract and NMZombieVisualTargetContract.ClientCacheTtlTicks) or 0
    NMClientZombieVisualTargetCache._receivedTick = tonumber(NMClientZombieVisualTargetCache._tick) or 0
    NMClientZombieVisualTargetCache._hasSnapshot = true
    NMClientZombieVisualTargetCache._staleLoggedRevision = 0
    NMClientZombieVisualTargetCache._staleLoggedAge = 0
    clearTargets()
    local records = args and args.targetRecords or nil
    if type(records) == "table" then
        NMClientZombieVisualTargetCache._targets = NMZombieVisualTargetContract and NMZombieVisualTargetContract.buildRecordLookup and NMZombieVisualTargetContract.buildRecordLookup(records) or {}
        for _ in pairs(NMClientZombieVisualTargetCache._targets) do
            NMClientZombieVisualTargetCache._targetCount = (tonumber(NMClientZombieVisualTargetCache._targetCount) or 0) + 1
        end
    else
        local targets = args and args.targetIds or nil
        if type(targets) == "table" then
            for i = 1, #targets do
                local zombieId = tostring(targets[i] or "")
                if zombieId ~= "" then
                    if type(NMClientZombieVisualTargetCache._targets[zombieId]) ~= "table" then
                        NMClientZombieVisualTargetCache._targetCount = (tonumber(NMClientZombieVisualTargetCache._targetCount) or 0) + 1
                    end
                    NMClientZombieVisualTargetCache._targets[zombieId] = {
                        zombieId = zombieId
                    }
                end
            end
        end
    end
    logSummary(
        "target_cache_update",
        string.format(
            "revision=%s targets=%s candidates=%s published=%s",
            tostring(revision),
            tostring(NMClientZombieVisualTargetCache._targetCount or 0),
            tostring(args and args.targetCandidates or 0),
            tostring(args and args.targetPublished or 0)
        )
    )
    return true
end

function NMClientZombieVisualTargetCache.onTick()
    NMClientZombieVisualTargetCache._tick = (tonumber(NMClientZombieVisualTargetCache._tick) or 0) + 1
    if not isMPClientRuntime() then
        return
    end
    local ttl = tonumber(NMClientZombieVisualTargetCache._ttlTicks) or 0
    if ttl <= 0 then
        return
    end
    local ageTicks = (tonumber(NMClientZombieVisualTargetCache._tick) or 0) - (tonumber(NMClientZombieVisualTargetCache._receivedTick) or 0)
    local overdueThreshold = ttl * 4
    if ageTicks < overdueThreshold then
        return
    end
    local revision = tonumber(NMClientZombieVisualTargetCache._revision) or 0
    if revision <= 0 then
        return
    end
    if revision ~= (tonumber(NMClientZombieVisualTargetCache._staleLoggedRevision) or 0) then
        NMClientZombieVisualTargetCache._staleLoggedRevision = revision
        NMClientZombieVisualTargetCache._staleLoggedAge = 0
    end
    local lastLoggedAge = tonumber(NMClientZombieVisualTargetCache._staleLoggedAge) or 0
    if ageTicks < (lastLoggedAge + overdueThreshold) then
        return
    end
    NMClientZombieVisualTargetCache._staleLoggedAge = ageTicks
    logSummary(
        "target_cache_overdue",
        string.format(
            "revision=%s targets=%s ageTicks=%s ttl=%s",
            tostring(revision),
            tostring(NMClientZombieVisualTargetCache._targetCount or 0),
            tostring(ageTicks),
            tostring(ttl)
        )
    )
end

function NMClientZombieVisualTargetCache.hasAuthoritativeTargets()
    if isMPClientRuntime() then
        return (tonumber(NMClientZombieVisualTargetCache._revision) or 0) > 0 and NMClientZombieVisualTargetCache._hasSnapshot == true
    end
    return isSPLocalRuntime()
end

function NMClientZombieVisualTargetCache.getZombieDecision(zombie)
    if isMPClientRuntime() then
        local zombieId = NMZombieVisualTargetContract and NMZombieVisualTargetContract.getZombieId and NMZombieVisualTargetContract.getZombieId(zombie) or tostring(zombie or "")
        local record = NMClientZombieVisualTargetCache._targets[tostring(zombieId or "")]
        local selected = type(record) == "table"
        return {
            authoritative = NMClientZombieVisualTargetCache.hasAuthoritativeTargets() == true,
            selected = selected,
            state = selected and "selected" or "excluded",
            source = "mp_snapshot",
            zombieId = tostring(zombieId or ""),
            variantId = tostring(record and record.variantId or ""),
            fullType = tostring(record and record.fullType or ""),
            attachmentLocation = tostring(record and record.attachmentLocation or ""),
            modelAttachmentName = tostring(record and record.modelAttachmentName or "")
        }
    end
    local stampedDecision = getSPStampedDecision(zombie)
    if stampedDecision then
        return stampedDecision
    end
    return {
        authoritative = false,
        selected = false,
        state = isSPLocalRuntime() and "pending" or "unknown",
        source = "none",
        zombieId = tostring(NMZombieVisualTargetContract and NMZombieVisualTargetContract.getZombieId and NMZombieVisualTargetContract.getZombieId(zombie) or zombie or "")
    }
end

function NMClientZombieVisualTargetCache.shouldRenderZombie(zombie)
    local decision = NMClientZombieVisualTargetCache.getZombieDecision and NMClientZombieVisualTargetCache.getZombieDecision(zombie) or nil
    if type(decision) ~= "table" then
        return false
    end
    if decision.authoritative ~= true then
        return false
    end
    return decision.selected == true
end

function NMClientZombieVisualTargetCache.isAuthoritativeZombie(zombie)
    local decision = NMClientZombieVisualTargetCache.getZombieDecision and NMClientZombieVisualTargetCache.getZombieDecision(zombie) or nil
    return type(decision) == "table" and decision.authoritative == true
end

function NMClientZombieVisualTargetCache.isAuthorityDrivenRuntime()
    if isMPClientRuntime() then
        return NMClientZombieVisualTargetCache.hasAuthoritativeTargets() == true
    end
    return isSPLocalRuntime()
end

function NMClientZombieVisualTargetCache.getZombieId(zombie)
    local zombieId = NMZombieVisualTargetContract and NMZombieVisualTargetContract.getZombieId and NMZombieVisualTargetContract.getZombieId(zombie) or tostring(zombie or "")
    return tostring(zombieId or "")
end

return NMClientZombieVisualTargetCache
