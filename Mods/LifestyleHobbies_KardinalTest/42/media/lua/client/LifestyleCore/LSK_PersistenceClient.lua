require "LifestyleCore/LSK_PersistenceSchema"
require "LifestyleCore/LSK_Features"

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.PersistenceClient = LifestyleSecure.PersistenceClient or {}

local Client = LifestyleSecure.PersistenceClient
local Schema = LifestyleSecure.PersistenceSchema

Client.COMMAND_MODULE = "LSKPersistence"
Client.state = Client.state or {
    revision = 0,
    baseline = {},
    pending = false,
    sentData = nil,
    requested = false,
    migrationReport = nil,
}

local function validPlayer(player)
    return player and player.getModData and player:getModData() or nil
end

local function replaceOwnedData(target, source)
    local clean = Schema.sanitizePlayerData(source)
    for key in pairs(Schema.playerKeys) do
        target[key] = nil
    end
    for key, value in pairs(clean) do
        target[key] = value
    end
end

local function ensureLocalNamespace(player)
    local modData = validPlayer(player)
    if not modData then
        return nil
    end
    local secure = modData[Schema.NAMESPACE]
    if type(secure) ~= "table" then
        secure = {
            schemaVersion = Schema.schemaVersion,
            revision = 0,
            migrated = false,
            dirty = false,
            data = {},
        }
        modData[Schema.NAMESPACE] = secure
    end
    secure.data = Schema.sanitizePlayerData(secure.data)
    secure.revision = math.max(0, math.floor(tonumber(secure.revision) or 0))
    secure.schemaVersion = Schema.schemaVersion
    if secure.migrated ~= true then
        secure.data = Schema.sanitizePlayerData(modData)
        secure.migrated = true
        secure.dirty = next(secure.data) ~= nil
        if secure.dirty then
            secure.revision = secure.revision + 1
        end
    end
    return secure
end

function Client.requestSnapshot(player)
    player = player or getPlayer()
    if not validPlayer(player) or not isClient() then
        return false
    end
    Client.state.requested = true
    sendClientCommand(player, Client.COMMAND_MODULE, "RequestSnapshot", {})
    return true
end

function Client.applySnapshot(player, snapshot)
    local modData = validPlayer(player)
    if not modData or type(snapshot) ~= "table" then
        return false
    end

    local cleanData = Schema.sanitizePlayerData(snapshot.data)
    local postSendDelta
    if Client.state.pending and Client.state.sentData then
        postSendDelta = Schema.createDelta(modData, Client.state.sentData)
    end

    replaceOwnedData(modData, cleanData)
    if postSendDelta and not Schema.isDeltaEmpty(postSendDelta) then
        Schema.applyDelta(modData, postSendDelta)
    end

    local secure = ensureLocalNamespace(player)
    if secure then
        secure.data = Schema.copyPlayerData(cleanData)
        secure.revision = math.max(0, math.floor(tonumber(snapshot.revision) or 0))
        secure.migrated = true
        secure.dirty = false
    end

    Client.state.revision = math.max(0, math.floor(tonumber(snapshot.revision) or 0))
    Client.state.baseline = Schema.copyPlayerData(cleanData)
    Client.state.pending = false
    Client.state.sentData = nil
    Client.state.requested = true

    -- Empty/missing Ambitions after snapshot must be re-seeded (one-shot seed can race join).
    if type(modData.Ambitions) ~= "table" then
        modData.Ambitions = {}
    end
    if LSAmbtMng then
        LSAmbtMng.LSCheckCustomAmbts = false
        if LSAmbtMng.ensureAmbitionsSeeded then
            LSAmbtMng.ensureAmbitionsSeeded(player)
        end
    end
    return true
end

function Client.flush(player)
    player = player or getPlayer()
    local modData = validPlayer(player)
    if not modData or (player.isDead and player:isDead()) then
        return false
    end
    if LifestyleSecure and LifestyleSecure.Features
        and LifestyleSecure.Features.IsModActive
        and not LifestyleSecure.Features.IsModActive() then
        return false
    end

    if not isClient() then
        local secure = ensureLocalNamespace(player)
        if not secure then
            return false
        end
        local delta = Schema.createDelta(modData, secure.data)
        local changed = Schema.applyDelta(secure.data, delta)
        if changed then
            secure.revision = secure.revision + 1
            secure.dirty = true
        end
        return changed
    end

    if not Client.state.requested then
        Client.requestSnapshot(player)
        return false
    end
    if Client.state.pending then
        return false
    end

    if type(Client.state.baseline) ~= "table" then
        Client.state.baseline = {}
    end

    local current = Schema.sanitizePlayerData(modData)
    local ok, delta = pcall(Schema.createDelta, current, Client.state.baseline)
    if not ok or type(delta) ~= "table" then
        return false
    end
    local emptyOk, isEmpty = pcall(Schema.isDeltaEmpty, delta)
    if not emptyOk or isEmpty then
        return false
    end

    Client.state.pending = true
    Client.state.sentData = Schema.copyPlayerData(current)
    sendClientCommand(player, Client.COMMAND_MODULE, "SubmitDelta", {
        revision = Client.state.revision,
        delta = delta,
    })
    return true
end

function Client.requestMigrationReport(player)
    player = player or getPlayer()
    if not validPlayer(player) or not isClient() then
        return false
    end
    sendClientCommand(player, Client.COMMAND_MODULE, "MigrationReport", {})
    return true
end

function Client.getMigrationReport()
    return Client.state.migrationReport
end

local function onServerCommand(module, command, args)
    if module ~= Client.COMMAND_MODULE then
        return
    end
    if command == "Snapshot" then
        Client.applySnapshot(getPlayer(), args)
    elseif command == "MigrationReport" then
        Client.state.migrationReport = type(args) == "table" and args or nil
    end
end

local function onCreatePlayer(_, player)
    if isClient() then
        Client.state.requested = false
        Client.state.pending = false
        Client.state.sentData = nil
        Client.requestSnapshot(player)
    else
        ensureLocalNamespace(player)
    end
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnCreatePlayer.Add(onCreatePlayer)

return Client
