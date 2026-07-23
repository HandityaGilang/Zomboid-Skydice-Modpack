require "LifestyleCore/LSK_PersistenceSchema"

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.Persistence = LifestyleSecure.Persistence or {}

local Persistence = LifestyleSecure.Persistence
local Schema = LifestyleSecure.PersistenceSchema

Persistence.COMMAND_MODULE = "LSKPersistence"
Persistence.stats = Persistence.stats or {
    playersMigrated = 0,
    keysMigrated = 0,
    migrationsSkipped = 0,
    deltasAccepted = 0,
    deltasRejected = 0,
}
Persistence.commandTimes = Persistence.commandTimes or {}
Persistence.lastCommandCleanup = Persistence.lastCommandCleanup or 0

local function countKeys(data)
    local count = 0
    if type(data) == "table" then
        for _ in pairs(data) do
            count = count + 1
        end
    end
    return count
end

local function newNamespace()
    return {
        schemaVersion = Schema.schemaVersion,
        revision = 0,
        migrated = false,
        migratedKeyCount = 0,
        dirty = false,
        data = {},
    }
end

local function validPlayer(player)
    return player and player.getModData and player:getModData() or nil
end

local function playerKey(player)
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return player and player.getUsername and tostring(player:getUsername()) or "unknown"
end

local function commandAllowed(player, command)
    local now = getTimestampMs and getTimestampMs() or 0
    if now - Persistence.lastCommandCleanup > 60000 then
        Persistence.lastCommandCleanup = now
        for oldKey, timestamp in pairs(Persistence.commandTimes) do
            if now - timestamp > 600000 then
                Persistence.commandTimes[oldKey] = nil
            end
        end
    end
    local key = playerKey(player) .. ":" .. tostring(command)
    local minimumDelay = command == "SubmitDelta" and 2000 or 750
    local previous = Persistence.commandTimes[key] or 0
    if now - previous < minimumDelay then
        return false
    end
    Persistence.commandTimes[key] = now
    if command == "MigrationReport" and player and player.getAccessLevel then
        return string.lower(tostring(player:getAccessLevel() or "")) == "admin"
    end
    return command == "RequestSnapshot"
        or command == "SubmitDelta"
        or command == "MigrationReport"
end

function Persistence.ensure(player)
    local modData = validPlayer(player)
    if not modData then
        return nil
    end

    local secure = modData[Schema.NAMESPACE]
    if type(secure) ~= "table" then
        secure = newNamespace()
        modData[Schema.NAMESPACE] = secure
    end
    secure.data = Schema.sanitizePlayerData(secure.data)
    secure.schemaVersion = Schema.schemaVersion
    secure.revision = math.max(0, math.floor(tonumber(secure.revision) or 0))
    secure.migratedKeyCount = math.max(0, math.floor(tonumber(secure.migratedKeyCount) or 0))
    secure.dirty = secure.dirty == true

    if secure.migrated ~= true then
        local legacy = Schema.sanitizePlayerData(modData)
        local migrated = 0
        for key, value in pairs(legacy) do
            if secure.data[key] == nil then
                secure.data[key] = value
                migrated = migrated + 1
            end
        end
        secure.migrated = true
        secure.migratedKeyCount = migrated
        if migrated > 0 then
            secure.revision = secure.revision + 1
            secure.dirty = true
            Persistence.stats.playersMigrated = Persistence.stats.playersMigrated + 1
            Persistence.stats.keysMigrated = Persistence.stats.keysMigrated + migrated
        else
            Persistence.stats.migrationsSkipped = Persistence.stats.migrationsSkipped + 1
        end
    end
    return secure
end

local function mirrorDeltaToLegacy(modData, cleanDelta)
    for key, value in pairs(cleanDelta.set) do
        modData[key] = Schema.sanitizeValue(value)
    end
    for i = 1, #cleanDelta.remove do
        modData[cleanDelta.remove[i]] = nil
    end
end

function Persistence.getSnapshot(player)
    local secure = Persistence.ensure(player)
    if not secure then
        return nil
    end
    return {
        schemaVersion = Schema.schemaVersion,
        revision = secure.revision,
        data = Schema.copyPlayerData(secure.data),
    }
end

function Persistence.sendSnapshot(player)
    local snapshot = Persistence.getSnapshot(player)
    if snapshot and sendServerCommand then
        sendServerCommand(player, Persistence.COMMAND_MODULE, "Snapshot", snapshot)
    end
    return snapshot
end

function Persistence.applyClientDelta(player, revision, delta)
    local modData = validPlayer(player)
    local secure = Persistence.ensure(player)
    if not modData or not secure then
        return false, "invalid-player"
    end

    local expectedRevision = tonumber(revision)
    if not expectedRevision
        or expectedRevision < 0
        or expectedRevision ~= math.floor(expectedRevision)
        or math.floor(expectedRevision) ~= secure.revision then
        Persistence.stats.deltasRejected = Persistence.stats.deltasRejected + 1
        return false, "revision-mismatch"
    end
    if type(delta) ~= "table"
        or tonumber(delta.schemaVersion) ~= Schema.schemaVersion then
        Persistence.stats.deltasRejected = Persistence.stats.deltasRejected + 1
        return false, "schema-mismatch"
    end

    local changed, cleanDelta = Schema.applyDelta(secure.data, delta)
    if changed then
        mirrorDeltaToLegacy(modData, cleanDelta)
        secure.revision = secure.revision + 1
        secure.dirty = true
        Persistence.stats.deltasAccepted = Persistence.stats.deltasAccepted + 1
    end
    return true, changed and "applied" or "unchanged"
end

function Persistence.getMigrationReport(player)
    local secure = player and Persistence.ensure(player) or nil
    return {
        playersMigrated = Persistence.stats.playersMigrated,
        keysMigrated = Persistence.stats.keysMigrated,
        migrationsSkipped = Persistence.stats.migrationsSkipped,
        deltasAccepted = Persistence.stats.deltasAccepted,
        deltasRejected = Persistence.stats.deltasRejected,
        playerMigrated = secure and secure.migrated == true and 1 or 0,
        playerMigratedKeys = secure and secure.migratedKeyCount or 0,
        revision = secure and secure.revision or 0,
        storedKeys = secure and countKeys(secure.data) or 0,
    }
end

function Persistence.logMigrationReport(player)
    local report = Persistence.getMigrationReport(player)
    print("[LifestyleSecure] migration counts"
        .. " players=" .. tostring(report.playersMigrated)
        .. " keys=" .. tostring(report.keysMigrated)
        .. " skipped=" .. tostring(report.migrationsSkipped)
        .. " stored=" .. tostring(report.storedKeys)
        .. " revision=" .. tostring(report.revision))
    return report
end

function Persistence.handleCommand(player, command, args)
    local modActive = true
    if LifestyleSecure and LifestyleSecure.Features and LifestyleSecure.Features.IsModActive then
        modActive = LifestyleSecure.Features.IsModActive()
    end

    if command == "RequestSnapshot" then
        -- Snapshot is cheap and keeps client baseline consistent when re-enabled.
        Persistence.sendSnapshot(player)
        return true
    end
    if command == "SubmitDelta" then
        if not modActive then
            Persistence.sendSnapshot(player)
            return false
        end
        local payload = type(args) == "table" and args or {}
        local accepted = Persistence.applyClientDelta(
            player,
            payload.revision or payload[1],
            payload.delta or payload[2]
        )
        Persistence.sendSnapshot(player)
        return accepted
    end
    if command == "MigrationReport" then
        local report = Persistence.logMigrationReport(player)
        sendServerCommand(player, Persistence.COMMAND_MODULE, "MigrationReport", report)
        return true
    end
    return false
end

local function onClientCommand(module, command, player, args)
    if module == Persistence.COMMAND_MODULE and commandAllowed(player, command) then
        Persistence.handleCommand(player, command, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)

return Persistence
