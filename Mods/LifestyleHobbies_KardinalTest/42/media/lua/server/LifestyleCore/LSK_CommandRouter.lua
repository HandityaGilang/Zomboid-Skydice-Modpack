require "LifestyleCore/LSK_NetSchema"
require "LifestyleCore/LSK_Metrics"

LSK_CommandRouter = LSK_CommandRouter or {}

local buckets = {}
local nonces = {}
local nonceSequence = 0
local lastCleanup = 0

local function nowMilliseconds()
    if getTimestampMs then
        return getTimestampMs()
    end
    return os.time() * 1000
end

local function playerKey(player)
    if not player then
        return "no-player"
    end
    if player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    if player.getUsername then
        return tostring(player:getUsername())
    end
    return tostring(player)
end

local function commandLabel(command)
    local text = tostring(command or "nil")
    if string.len(text) > 64 then
        return string.sub(text, 1, 64)
    end
    return text
end

local function audit(player, command, result, reason)
    LSK_Metrics.increment(result == "accepted" and "accepted" or "rejected")
    LSK_Metrics.increment(result .. ":" .. commandLabel(command))
    if result ~= "accepted" then
        print("[LSK Security] reject player=" .. playerKey(player)
            .. " command=" .. commandLabel(command)
            .. " reason=" .. tostring(reason or "unknown"))
    end
end

local function isAdmin(player)
    if not isServer() and not isClient() then
        return true
    end
    if not player or not player.getAccessLevel then
        return false
    end
    local ok, access = pcall(function()
        return player:getAccessLevel()
    end)
    return ok and string.lower(tostring(access or "")) == "admin"
end

LSK_CommandRouter.isAdmin = isAdmin

local function validatePayload(root)
    local seen = {}
    local entries = 0

    local function visit(value, depth)
        local valueType = type(value)
        if valueType == "number" then
            return LSK_NetSchema.isFiniteNumber(value), "non_finite_number"
        elseif valueType == "string" then
            return string.len(value) <= LSK_NetSchema.MAX_STRING_LENGTH, "string_too_long"
        elseif valueType == "nil" or valueType == "boolean" or valueType == "userdata" then
            return true
        elseif valueType ~= "table" then
            return false, "unsafe_type"
        end
        if depth > LSK_NetSchema.MAX_PAYLOAD_DEPTH then
            return false, "payload_too_deep"
        end
        if seen[value] then
            return false, "cyclic_payload"
        end
        seen[value] = true
        for key, child in pairs(value) do
            entries = entries + 1
            if entries > LSK_NetSchema.MAX_PAYLOAD_ENTRIES then
                seen[value] = nil
                return false, "payload_too_large"
            end
            local keyType = type(key)
            if keyType ~= "string" and keyType ~= "number" then
                seen[value] = nil
                return false, "unsafe_key"
            end
            if keyType == "string" and string.len(key) > 96 then
                seen[value] = nil
                return false, "key_too_long"
            end
            if keyType == "number" and not LSK_NetSchema.isFiniteNumber(key) then
                seen[value] = nil
                return false, "invalid_key"
            end
            local ok, reason = visit(child, depth + 1)
            if not ok then
                seen[value] = nil
                return false, reason
            end
        end
        seen[value] = nil
        return true
    end

    return visit(root, 1)
end

local function consumeToken(player, policy)
    local key = playerKey(player) .. ":" .. tostring(policy.group)
    local currentTime = nowMilliseconds()
    local bucket = buckets[key]
    if not bucket then
        bucket = {
            tokens = policy.burst,
            updated = currentTime,
        }
        buckets[key] = bucket
    end
    local elapsed = math.max(0, currentTime - bucket.updated) / 1000
    bucket.updated = currentTime
    bucket.tokens = math.min(policy.burst, bucket.tokens + elapsed * policy.rate)
    if bucket.tokens < 1 then
        LSK_Metrics.increment("rate_limited")
        return false
    end
    bucket.tokens = bucket.tokens - 1
    return true
end

local function extractCoordinates(args, distancePolicy)
    if distancePolicy.nestedIndex then
        local nested = args[distancePolicy.nestedIndex]
        if type(nested) ~= "table" then
            return nil
        end
        return nested[1], nested[2], nested[3]
    end
    local indices = distancePolicy.indices
    if not indices then
        return nil
    end
    return args[indices[1]], args[indices[2]], args[indices[3]]
end

local function validateDistance(player, args, distancePolicy)
    if not player or not player.getX or not player.getY or not player.getZ then
        return false
    end
    local x, y, z = extractCoordinates(args, distancePolicy)
    if distancePolicy.optional and x == nil and y == nil and z == nil then
        return true
    end
    if not LSK_NetSchema.number(x) or not LSK_NetSchema.number(y)
        or not LSK_NetSchema.number(z, 0, 32) then
        return false
    end
    local dx = player:getX() - x
    local dy = player:getY() - y
    local dz = player:getZ() - z
    local maximum = distancePolicy.maximum or 10
    return (dx * dx + dy * dy + dz * dz) <= maximum * maximum
end

local function validateTarget(player, args, targetPolicy)
    local targetId = args[targetPolicy.index or 1]
    if not LSK_NetSchema.number(targetId, 0, 2147483647, true)
        or not getPlayerByOnlineID then
        return false
    end
    local target = getPlayerByOnlineID(targetId)
    if not target then
        return false
    end
    if targetPolicy.maximum and player and player.getX and target.getX then
        local dx = player:getX() - target:getX()
        local dy = player:getY() - target:getY()
        local dz = player:getZ() - target:getZ()
        if dx * dx + dy * dy + dz * dz > targetPolicy.maximum * targetPolicy.maximum then
            return false
        end
    end
    return true
end

local function cleanupExpired()
    local currentTime = nowMilliseconds()
    if currentTime - lastCleanup < 60000 then
        return
    end
    lastCleanup = currentTime
    for key, session in pairs(nonces) do
        if session.expiresAt <= currentTime then
            nonces[key] = nil
        end
    end
    for key, bucket in pairs(buckets) do
        if currentTime - bucket.updated > 600000 then
            buckets[key] = nil
        end
    end
end

function LSK_CommandRouter.beginNonce(player, actionName, ttlMilliseconds, context)
    cleanupExpired()
    if not LSK_NetSchema.identifier(actionName, 64) then
        return nil
    end
    nonceSequence = nonceSequence + 1
    local randomPart = ZombRand and ZombRand(1000000000) or math.random(1, 999999999)
    local nonce = tostring(nowMilliseconds()) .. "-" .. tostring(randomPart) .. "-" .. tostring(nonceSequence)
    local key = playerKey(player) .. ":" .. actionName
    -- Cap must match long open-ended actions (Yoga Wellness begin uses up to 30min).
    -- Old 300000 (5min) caused Wellness.complete -> invalid_or_expired_nonce mid-session.
    nonces[key] = {
        nonce = nonce,
        expiresAt = nowMilliseconds() + math.min(3600000, math.max(1000, ttlMilliseconds or 30000)),
        context = context,
    }
    return nonce
end

function LSK_CommandRouter.registerNonce(player, actionName, nonce, ttlMilliseconds, context)
    cleanupExpired()
    if not LSK_NetSchema.identifier(actionName, 64)
        or not LSK_NetSchema.string(nonce, 12, 128, "^[%w_%-]+$") then
        return false
    end
    local key = playerKey(player) .. ":" .. actionName
    nonces[key] = {
        nonce = nonce,
        startedAt = nowMilliseconds(),
        expiresAt = nowMilliseconds() + math.min(3600000, math.max(5000, ttlMilliseconds or 30000)),
        context = context,
    }
    return true
end

function LSK_CommandRouter.validateNonce(player, actionName, nonce)
    cleanupExpired()
    local key = playerKey(player) .. ":" .. tostring(actionName)
    local session = nonces[key]
    if not session or session.expiresAt < nowMilliseconds() then
        return false, nil
    end
    if type(nonce) ~= "string" or session.nonce ~= nonce then
        return false, nil
    end
    return true, session
end

function LSK_CommandRouter.cancelNonce(player, actionName)
    nonces[playerKey(player) .. ":" .. tostring(actionName)] = nil
end

function LSK_CommandRouter.consumeNonce(player, actionName, nonce)
    cleanupExpired()
    local key = playerKey(player) .. ":" .. tostring(actionName)
    local session = nonces[key]
    nonces[key] = nil
    if not session or session.expiresAt < nowMilliseconds() then
        return false, nil
    end
    if type(nonce) ~= "string" or session.nonce ~= nonce then
        return false, nil
    end
    return true, session.context
end

function LSK_CommandRouter.dispatch(command, player, args, handlers)
    cleanupExpired()
    local policy = LSK_NetSchema.getPolicy(command)
    local handler = handlers and handlers[command]
    if not policy or type(handler) ~= "function" then
        audit(player, command, "rejected", "unknown_command")
        return false
    end
    -- Master sandbox off: reject gameplay commands. Admin tools still allowed.
    if LifestyleSecure and LifestyleSecure.Features
        and LifestyleSecure.Features.IsModActive
        and not LifestyleSecure.Features.IsModActive()
        and not policy.admin then
        audit(player, command, "rejected", "mod_disabled")
        return false
    end
    if policy.admin and not isAdmin(player) then
        audit(player, command, "rejected", "admin_required")
        return false
    end
    local payloadOk, payloadReason = validatePayload(args)
    if not payloadOk then
        audit(player, command, "rejected", payloadReason)
        return false
    end
    local schemaOk, schemaReason = LSK_NetSchema.validatePolicy(policy, player, args)
    if not schemaOk then
        audit(player, command, "rejected", schemaReason)
        return false
    end
    if policy.distance and not validateDistance(player, args, policy.distance) then
        audit(player, command, "rejected", "distance")
        return false
    end
    if policy.target and not validateTarget(player, args, policy.target) then
        audit(player, command, "rejected", "invalid_target")
        return false
    end
    if policy.requiresAction then
        local proof = args.__lsk
        if type(proof) ~= "table" then
            audit(player, command, "rejected", "action_proof_missing")
            return false
        end
        local validAction, actionSession = LSK_CommandRouter.validateNonce(player, proof.action, proof.nonce)
        if not validAction then
            audit(player, command, "rejected", "action_proof_invalid")
            return false
        end
        -- B42 dedicated: TimedActions usually live on the client only.
        -- Server session from LSK_BeginAction is the authority, not hasTimedActions().
        args.__lskServerSession = actionSession
        args.__lskServerAction = proof.action
    end
    if not consumeToken(player, policy) then
        audit(player, command, "rejected", "rate_limit")
        return false
    end
    local ok, err = pcall(handler, player, args)
    if not ok then
        LSK_Metrics.increment("handler_failed")
        audit(player, command, "rejected", "handler_error")
        print("[LSK Security] handler error command=" .. commandLabel(command)
            .. " error=" .. tostring(err))
        return false
    end
    audit(player, command, "accepted")
    return true
end

return LSK_CommandRouter
