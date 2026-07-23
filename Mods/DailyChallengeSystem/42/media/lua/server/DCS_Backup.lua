local DCS_Backup = {}

local BACKUP_VERSION = 2
local BACKUP_PREFIX = "DCS_Backup_"
local BACKUP_SUFFIX = ".lua"
local AUTO_FILENAME = "auto_backup" .. BACKUP_SUFFIX
local INDEX_FILENAME = "backup_index.txt"

DCS_Backup.knownBackups = {}
DCS_Backup.lastAutoBackup = 0
local AUTO_THROTTLE_SEC = 60

local function getAllPlayers()
    return DCS_Env.players()
end

local function getServerDir()
    if DCS_Env and DCS_Env.isSP() then
        return "DailyChallengeSystem/Singleplayer/"
    end
    local name = getServerName and getServerName() or "default"
    return "DailyChallengeSystem/" .. name .. "/"
end

local function serializeValue(val)
    if val == nil then return "" end
    if type(val) == "boolean" then return val and "true" or "false" end
    return tostring(val)
end

local function deserializeValue(val, targetType)
    if val == nil or val == "" then return nil end
    if targetType == "number" then
        return tonumber(val)
    elseif targetType == "boolean" then
        return val == "true"
    end
    return val
end

local function escapeUsername(name)
    if not name then return "" end
    return name:gsub("[%.=,|]", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function unescapeUsername(name)
    if not name then return "" end
    return name:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

local function serializeArray(arr)
    if not arr or type(arr) ~= "table" then return "" end
    local parts = {}
    for _, v in ipairs(arr) do
        parts[#parts + 1] = tostring(v)
    end
    return table.concat(parts, ",")
end

local function deserializeArray(str)
    if not str or str == "" then return {} end
    local result = {}
    for word in str:gmatch("[^,]+") do
        result[#result + 1] = word
    end
    return result
end

local function serializeFlatTable(t)
    if not t or type(t) ~= "table" then return "" end
    local parts = {}
    for k, v in pairs(t) do
        parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
    end
    return table.concat(parts, ",")
end

local function deserializeFlatTable(str)
    if not str or str == "" then return {} end
    local result = {}
    for pair in str:gmatch("[^,]+") do
        local k, v = pair:match("^(.-)=(.+)$")
        if k and v then
            result[k] = tonumber(v) or v
        end
    end
    return result
end

local function serializeNestedFlatTable(t)
    if not t or type(t) ~= "table" then return "" end
    local parts = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            local inner = {}
            for _, val in ipairs(v) do
                inner[#inner + 1] = tostring(val)
            end
            parts[#parts + 1] = tostring(k) .. "=" .. table.concat(inner, ":")
        else
            parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
        end
    end
    return table.concat(parts, ",")
end

local function deserializeNestedFlatTable(str)
    if not str or str == "" then return {} end
    local result = {}
    for pair in str:gmatch("[^,]+") do
        local k, v = pair:match("^(.-)=(.+)$")
        if k and v then
            if v:find(":") then
                local arr = {}
                for val in v:gmatch("[^:]+") do
                    arr[#arr + 1] = tonumber(val) or val
                end
                result[k] = arr
            else
                result[k] = tonumber(v) or v
            end
        end
    end
    return result
end

local function serializeSpeedrun(data)
    if not data or type(data) ~= "table" then return "" end
    local parts = {}
    for _, entry in ipairs(data) do
        if type(entry) == "table" then
            local time = entry.time or 0
            local date = entry.date or ""
            parts[#parts + 1] = (entry.name or "") .. "=" .. tostring(time) .. "," .. tostring(date)
        end
    end
    return table.concat(parts, "|")
end

local function deserializeSpeedrun(str)
    if not str or str == "" then return {} end
    local result = {}
    for entry in str:gmatch("[^|]+") do
        local name, rest = entry:match("^(.-)=(.+)$")
        if name and rest then
            local timeStr, dateStr = rest:match("^(.-),(.*)$")
            if timeStr and dateStr then
                result[#result + 1] = { name = name, time = tonumber(timeStr) or 0, date = dateStr }
            else
                result[#result + 1] = { name = name, time = tonumber(rest) or 0, date = "" }
            end
        end
    end
    return result
end

local function getAutoBackupPath()
    return getServerDir() .. AUTO_FILENAME
end

local function makeBackupFilename()
    return getServerDir() .. BACKUP_PREFIX .. os.date("!%Y-%m-%d_%H-%M-%S") .. BACKUP_SUFFIX
end

local function getIndexPath()
    return getServerDir() .. INDEX_FILENAME
end

local function buildBackupString()
    local lines = {}
    lines[#lines + 1] = "DCS_BACKUP_VERSION=" .. BACKUP_VERSION
    lines[#lines + 1] = "DCS_BACKUP_TIMESTAMP=" .. os.date("!%Y-%m-%dT%H:%M:%SZ")
    lines[#lines + 1] = ""

    local gmd = ModData.getOrCreate("DCS_Global")
    lines[#lines + 1] = "# GLOBAL"

    local cfg = gmd.shopConfig or {}
    lines[#lines + 1] = "GLOBAL.shopConfig.enabledItems=" .. serializeArray(cfg.enabledItems)
    lines[#lines + 1] = "GLOBAL.shopConfig.customCosts=" .. serializeFlatTable(cfg.customCosts)
    lines[#lines + 1] = "GLOBAL.shopConfig.customStock=" .. serializeNestedFlatTable(cfg.customStock)

    lines[#lines + 1] = "GLOBAL.debugResetVersion=" .. serializeValue(gmd.debugResetVersion or 0)
    lines[#lines + 1] = "GLOBAL.debugResetType=" .. serializeValue(gmd.debugResetType or "")

    local lb = gmd.leaderboard or {}
    lines[#lines + 1] = "GLOBAL.leaderboard.mostCompleted=" .. serializeFlatTable(lb.mostCompleted)
    lines[#lines + 1] = "GLOBAL.leaderboard.highestStreak=" .. serializeFlatTable(lb.highestStreak)
    lines[#lines + 1] = "GLOBAL.leaderboard.currentStreak=" .. serializeFlatTable(lb.currentStreak)
    lines[#lines + 1] = "GLOBAL.leaderboard.mostTokens=" .. serializeFlatTable(lb.mostTokens)
    lines[#lines + 1] = "GLOBAL.leaderboard.speedrun1=" .. serializeSpeedrun(lb.speedrun1)
    lines[#lines + 1] = "GLOBAL.leaderboard.speedrun7=" .. serializeSpeedrun(lb.speedrun7)
    lines[#lines + 1] = ""

    if DCS_Env and DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        lines[#lines + 1] = "# SP_WALLET"
        lines[#lines + 1] = "SP_WALLET.tokens=" .. serializeValue(wallet.tokens or 0)
        local hist = wallet.history or {}
        for i, h in ipairs(hist) do
            local pfx = "SP_WALLET.history." .. i
            lines[#lines + 1] = pfx .. ".id=" .. serializeValue(h.id or "")
            lines[#lines + 1] = pfx .. ".name=" .. serializeValue(h.name or "")
            lines[#lines + 1] = pfx .. ".longestStreak=" .. serializeValue(h.longestStreak or 0)
            lines[#lines + 1] = pfx .. ".totalChallengesCompleted=" .. serializeValue(h.totalChallengesCompleted or 0)
            lines[#lines + 1] = pfx .. ".speedrun1Attempts=" .. serializeSpeedrun(h.speedrun1Attempts or {})
            lines[#lines + 1] = pfx .. ".speedrun7Attempts=" .. serializeSpeedrun(h.speedrun7Attempts or {})
        end
        lines[#lines + 1] = "SP_WALLET.historyCount=" .. tostring(#hist)
        lines[#lines + 1] = ""
    end

    lines[#lines + 1] = "# PLAYERS"
    local store = ModData.getOrCreate("DCS_PlayerStore")
    for username, pd in pairs(store.players or {}) do
        if pd then
            local prefix = "PLAYER." .. escapeUsername(username)

            lines[#lines + 1] = prefix .. ".currency=" .. serializeValue(pd.currency)
            lines[#lines + 1] = prefix .. ".streak=" .. serializeValue(pd.streak)
            lines[#lines + 1] = prefix .. ".streakLevel=" .. serializeValue(pd.streakLevel)
            lines[#lines + 1] = prefix .. ".lifetimeCompleted=" .. serializeValue(pd.lifetimeCompleted)
            lines[#lines + 1] = prefix .. ".lastCompletedDay=" .. serializeValue(pd.lastCompletedDay)
            lines[#lines + 1] = prefix .. ".bonusAwardedDay=" .. serializeValue(pd.bonusAwardedDay)
            lines[#lines + 1] = prefix .. ".challengeStartDay=" .. serializeValue(pd.challengeStartDay)
            lines[#lines + 1] = prefix .. ".challengeStartTime=" .. serializeValue(pd.challengeStartTime)
            lines[#lines + 1] = prefix .. ".speedrun1DoneToday=" .. serializeValue(pd.speedrun1DoneToday)
            lines[#lines + 1] = prefix .. ".speedrun7DoneToday=" .. serializeValue(pd.speedrun7DoneToday)
            lines[#lines + 1] = prefix .. ".dataVersion=" .. serializeValue(pd.dataVersion)

            local completedArr = {}
            if pd.dailyCompleted and type(pd.dailyCompleted) == "table" then
                for chId, done in pairs(pd.dailyCompleted) do
                    if done then completedArr[#completedArr + 1] = chId end
                end
            end
            lines[#lines + 1] = prefix .. ".dailyCompleted=" .. serializeArray(completedArr)

            lines[#lines + 1] = prefix .. ".dailyKills=" .. serializeValue(pd.dailyKills)
            lines[#lines + 1] = prefix .. ".killsResetDay=" .. serializeValue(pd.killsResetDay)

            lines[#lines + 1] = prefix .. ".dailyKillsByWeapon=" .. serializeFlatTable(pd.dailyKillsByWeapon)
            lines[#lines + 1] = prefix .. ".killsByWeaponResetDay=" .. serializeValue(pd.killsByWeaponResetDay)

            lines[#lines + 1] = prefix .. ".dailyKillsByCategory=" .. serializeFlatTable(pd.dailyKillsByCategory)
            lines[#lines + 1] = prefix .. ".killsByCategoryResetDay=" .. serializeValue(pd.killsByCategoryResetDay)

            lines[#lines + 1] = prefix .. ".dailyProgress=" .. serializeFlatTable(pd.dailyProgress)
            lines[#lines + 1] = prefix .. ".progressResetDay=" .. serializeValue(pd.progressResetDay)

            for _, id in ipairs(DCS_Challenges.WindowIds) do
                lines[#lines + 1] = prefix .. "." .. id .. "X=" .. serializeValue(pd[id .. "X"])
                lines[#lines + 1] = prefix .. "." .. id .. "Y=" .. serializeValue(pd[id .. "Y"])
            end

            lines[#lines + 1] = ""
        end
    end

    return table.concat(lines, "\n")
end

function DCS_Backup.loadIndex()
    local index = {}
    local reader = getFileReader(getIndexPath(), false)
    if reader then
        local line = reader:readLine()
        while line do
            if line ~= "" then
                local fn, ts = line:match("^(.+)|(.+)$")
                if fn and ts then
                    index[#index + 1] = { filename = fn, timestamp = ts }
                end
            end
            line = reader:readLine()
        end
        reader:close()
    end
    return index
end

local function saveIndex()
    local lines = {}
    for _, entry in ipairs(DCS_Backup.knownBackups) do
        lines[#lines + 1] = entry.filename .. "|" .. entry.timestamp
    end
    local writer = getFileWriter(getIndexPath(), true, false)
    if writer then
        writer:writeln(table.concat(lines, "\n"))
        writer:close()
    end
end

local function addToIndex(filename, timestamp)
    for _, entry in ipairs(DCS_Backup.knownBackups) do
        if entry.filename == filename then return end
    end
    DCS_Backup.knownBackups[#DCS_Backup.knownBackups + 1] = { filename = filename, timestamp = timestamp }
    saveIndex()
end

function DCS_Backup.export()
    local filename = makeBackupFilename()
    local content = buildBackupString()
    local writer = getFileWriter(filename, true, false)
    if not writer then
        print("[DCS] Backup FAILED: getFileWriter returned nil for " .. filename)
        return false, filename
    end
    writer:writeln(content)
    writer:close()
    DCS_dprint("[DCS] Backup exported to " .. filename .. " (" .. #content .. " bytes)")

    local ts = filename:match("DCS_Backup_(.+)%.lua$")
    addToIndex(filename, ts or os.date("!%Y-%m-%d_%H-%M-%S"))

    return true, filename
end

function DCS_Backup.autoBackup(force)
    local now = os.time()
    if not force and (now - DCS_Backup.lastAutoBackup < AUTO_THROTTLE_SEC) then
        return false
    end
    DCS_Backup.lastAutoBackup = now

    local filename = getAutoBackupPath()
    local content = buildBackupString()
    local writer = getFileWriter(filename, true, false)
    if not writer then
        print("[DCS] Auto-backup FAILED: getFileWriter returned nil for " .. filename)
        return false
    end
    writer:writeln(content)
    writer:close()
    DCS_dprint("[DCS] Auto-backup written to " .. filename .. " (" .. #content .. " bytes)")

    addToIndex(filename, os.date("!%Y-%m-%d_%H-%M-%S"))

    return true
end

function DCS_Backup.listFiles()
    local seen = {}
    local unique = {}
    for _, b in ipairs(DCS_Backup.knownBackups) do
        if not seen[b.filename] then
            seen[b.filename] = true
            unique[#unique + 1] = b
        end
    end
    DCS_Backup.knownBackups = unique
    DCS_dprint("[DCS] listFiles: Returning " .. #unique .. " unique backups")
    table.sort(unique, function(a, b) return a.filename > b.filename end)
    return unique
end

local function parseLine(line)
    if not line or line == "" then return nil, nil end
    if line:sub(1, 1) == "#" then return nil, nil end
    local key, value = line:match("^(.-)=(.*)$")
    return key, value
end

function DCS_Backup.import(filename)
    if not filename or filename == "" then
        return false, "No filename provided"
    end

    DCS_dprint("[DCS] import: attempting to load " .. filename)

    local reader = getFileReader(filename, false)
    if not reader then
        print("[DCS] Restore FAILED: file not found — " .. filename)
        return false, "Backup file not found:\n" .. filename:gsub("/", "\n")
    end

    local lines = {}
    local line = reader:readLine()
    while line do
        lines[#lines + 1] = line
        line = reader:readLine()
    end
    reader:close()

    local version = nil
    local timestamp = nil
    for _, l in ipairs(lines) do
        local k, v = parseLine(l)
        if k == "DCS_BACKUP_VERSION" then version = tonumber(v) end
        if k == "DCS_BACKUP_TIMESTAMP" then timestamp = v end
        if version and timestamp then break end
    end

    if not version then
        print("[DCS] Restore FAILED: no version found in backup file")
        return false, "Invalid backup file (no version)"
    end
    if version > BACKUP_VERSION then
        print("[DCS] Restore FAILED: backup version " .. version .. " is newer than supported version " .. BACKUP_VERSION)
        return false, "Backup version too new (v" .. version .. ")"
    end
    DCS_dprint("[DCS] Restoring from backup v" .. version .. " (" .. (timestamp or "unknown date") .. ")")

    local data = {}
    for _, l in ipairs(lines) do
        local k, v = parseLine(l)
        if k then data[k] = v end
    end

    DCS_dprint("[DCS] import: parsed " .. tostring(data["SP_WALLET.tokens"] or "NIL") .. " SP_WALLET.tokens")
    DCS_dprint("[DCS] import: parsed " .. tostring(data["GLOBAL.leaderboard.speedrun1"] or "NIL") .. " speedrun1 (len)")
    local playerCount = 0
    for k, _ in pairs(data) do
        if k:sub(1, 7) == "PLAYER." then playerCount = playerCount + 1 end
    end
    DCS_dprint("[DCS] import: found " .. tostring(math.floor(playerCount / 15)) .. " player(s) in backup (~" .. playerCount .. " keys)")

    local gmd = ModData.getOrCreate("DCS_Global")

    if not gmd.shopConfig then
        gmd.shopConfig = { enabledItems = {}, customCosts = {}, customStock = {} }
    end
    local rawEnabled = data["GLOBAL.shopConfig.enabledItems"]
    if rawEnabled then
        gmd.shopConfig.enabledItems = deserializeArray(rawEnabled)
    end
    local rawCosts = data["GLOBAL.shopConfig.customCosts"]
    if rawCosts then
        gmd.shopConfig.customCosts = deserializeFlatTable(rawCosts)
    end
    local rawStock = data["GLOBAL.shopConfig.customStock"]
    if rawStock and rawStock ~= "" then
        gmd.shopConfig.customStock = deserializeNestedFlatTable(rawStock)
    end

    gmd.debugResetVersion = deserializeValue(data["GLOBAL.debugResetVersion"], "number")
    gmd.debugResetType = data["GLOBAL.debugResetType"] or ""

    if not gmd.leaderboard then
        gmd.leaderboard = {
            mostCompleted = {}, highestStreak = {}, currentStreak = {},
            speedrun1 = {}, speedrun7 = {}, mostTokens = {},
        }
    end
    gmd.leaderboard.mostCompleted = deserializeFlatTable(data["GLOBAL.leaderboard.mostCompleted"])
    gmd.leaderboard.highestStreak = deserializeFlatTable(data["GLOBAL.leaderboard.highestStreak"])
    gmd.leaderboard.currentStreak = deserializeFlatTable(data["GLOBAL.leaderboard.currentStreak"])
    gmd.leaderboard.mostTokens = deserializeFlatTable(data["GLOBAL.leaderboard.mostTokens"])
    gmd.leaderboard.speedrun1 = deserializeSpeedrun(data["GLOBAL.leaderboard.speedrun1"])
    gmd.leaderboard.speedrun7 = deserializeSpeedrun(data["GLOBAL.leaderboard.speedrun7"])

    ModData.transmit("DCS_Global")

    if DCS_Env and DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        local restoredTokens = deserializeValue(data["SP_WALLET.tokens"], "number")
        if restoredTokens then
            wallet.tokens = restoredTokens
            DCS_dprint("[DCS] Restore SP_WALLET: tokens=" .. tostring(wallet.tokens))
        else
            DCS_dprint("[DCS] Restore SP_WALLET: no SP_WALLET.tokens in backup (old format?)")
        end
        local histCount = tonumber(data["SP_WALLET.historyCount"]) or 0
        if histCount > 0 then
            wallet.history = {}
            for i = 1, histCount do
                local pfx = "SP_WALLET.history." .. i
                local entry = {
                    id = data[pfx .. ".id"] or "",
                    name = data[pfx .. ".name"] or "",
                    longestStreak = deserializeValue(data[pfx .. ".longestStreak"], "number") or 0,
                    totalChallengesCompleted = deserializeValue(data[pfx .. ".totalChallengesCompleted"], "number") or 0,
                    speedrun1Attempts = deserializeSpeedrun(data[pfx .. ".speedrun1Attempts"]) or {},
                    speedrun7Attempts = deserializeSpeedrun(data[pfx .. ".speedrun7Attempts"]) or {},
                }
                wallet.history[i] = entry
                DCS_dprint("[DCS] Restore SP_WALLET history[" .. i .. "]: name=" .. entry.name
                    .. " sr1=" .. tostring(#entry.speedrun1Attempts)
                    .. " sr7=" .. tostring(#entry.speedrun7Attempts)
                    .. " streak=" .. tostring(entry.longestStreak))
            end
            DCS_dprint("[DCS] Restore SP_WALLET: restored " .. histCount .. " history entries")
        else
            DCS_dprint("[DCS] Restore SP_WALLET: no history in backup (old format?)")
        end
    end

    local playerUsernames = {}
    local pfxPrefix = "PLAYER."
    for key, _ in pairs(data) do
        if key:sub(1, #pfxPrefix) == pfxPrefix then
            local escapedName = key:sub(#pfxPrefix + 1):match("^(.-)%.")
            if escapedName then
                local username = unescapeUsername(escapedName)
                if not playerUsernames[username] then
                    playerUsernames[username] = true
                end
            end
        end
    end

    local store = ModData.getOrCreate("DCS_PlayerStore")
    if not store.players then store.players = {} end
    local onlineByName = {}
    for _, p in ipairs(getAllPlayers()) do
        onlineByName[p:getUsername()] = p
    end

    local restoredCount = 0
    for uname, _ in pairs(playerUsernames) do
        local pd = store.players[uname] or {}
        local pfx = "PLAYER." .. escapeUsername(uname) .. "."

        pd.currency = deserializeValue(data[pfx .. "currency"], "number")
        DCS_dprint("[DCS] Restore PLAYER " .. uname .. ": currency=" .. tostring(pd.currency))

        pd.streak = deserializeValue(data[pfx .. "streak"], "number")
        pd.streakLevel = deserializeValue(data[pfx .. "streakLevel"], "number")
        pd.lifetimeCompleted = deserializeValue(data[pfx .. "lifetimeCompleted"], "number")
        pd.lastCompletedDay = data[pfx .. "lastCompletedDay"] or ""
        pd.bonusAwardedDay = data[pfx .. "bonusAwardedDay"] or ""
        pd.challengeStartDay = data[pfx .. "challengeStartDay"] or ""
        pd.challengeStartTime = deserializeValue(data[pfx .. "challengeStartTime"], "number")
        pd.speedrun1DoneToday = deserializeValue(data[pfx .. "speedrun1DoneToday"], "boolean")
        pd.speedrun7DoneToday = deserializeValue(data[pfx .. "speedrun7DoneToday"], "boolean")
        pd.dataVersion = deserializeValue(data[pfx .. "dataVersion"], "number")

        local completedArr = deserializeArray(data[pfx .. "dailyCompleted"])
        pd.dailyCompleted = {}
        for _, chId in ipairs(completedArr) do
            pd.dailyCompleted[chId] = true
        end

        pd.dailyKills = deserializeValue(data[pfx .. "dailyKills"], "number")
        pd.killsResetDay = data[pfx .. "killsResetDay"] or ""

        pd.dailyKillsByWeapon = deserializeFlatTable(data[pfx .. "dailyKillsByWeapon"])
        pd.killsByWeaponResetDay = data[pfx .. "killsByWeaponResetDay"] or ""

        pd.dailyKillsByCategory = deserializeFlatTable(data[pfx .. "dailyKillsByCategory"])
        pd.killsByCategoryResetDay = data[pfx .. "killsByCategoryResetDay"] or ""

        pd.dailyProgress = deserializeFlatTable(data[pfx .. "dailyProgress"])
        pd.progressResetDay = data[pfx .. "progressResetDay"] or ""

        for _, id in ipairs(DCS_Challenges.WindowIds) do
            pd[id .. "X"] = deserializeValue(data[pfx .. id .. "X"], "number") or pd[id .. "X"]
            pd[id .. "Y"] = deserializeValue(data[pfx .. id .. "Y"], "number") or pd[id .. "Y"]
        end

        pd.dataVersion = gmd.debugResetVersion or 0

        store.players[uname] = pd

        local online = onlineByName[uname]
        if online then
            online:getModData().DCS = pd
            online:transmitModData()
        end

        restoredCount = restoredCount + 1
        DCS_dprint("[DCS] Restored data for " .. uname)
    end

    ModData.add("DCS_PlayerStore", store)

    if DCS_Env and DCS_Env.isSP() then
        ModData.add("DCS_SP", ModData.getOrCreate("DCS_SP"))
        ModData.transmit("DCS_SP")
    end

    if DCS_Leaderboard and DCS_Leaderboard.broadcast then
        DCS_Leaderboard.broadcast()
    end

    DCS_dprint("[DCS] Restore complete: " .. restoredCount .. " player(s)")
    return true, restoredCount
end

function DCS_Backup.init()
    DCS_dprint("[DCS] init: Server dir = " .. getServerDir())
    local seen = {}

    local probeWriter = getFileWriter(getServerDir() .. ".dcs_init_probe", true, false)
    if probeWriter then
        probeWriter:close()
    end

    local reader = getFileReader(getIndexPath(), true)
    if reader then
        DCS_dprint("[DCS] init: Index file opened successfully")
        local line = reader:readLine()
        local count = 0
        while line do
            if line ~= "" then
                local fn, ts = line:match("^(.+)|(.+)$")
                if fn and ts and not seen[fn] then
                    seen[fn] = true
                    DCS_Backup.knownBackups[#DCS_Backup.knownBackups + 1] = { filename = fn, timestamp = ts }
                    count = count + 1
                end
            end
            line = reader:readLine()
        end
        reader:close()
        DCS_dprint("[DCS] init: Loaded " .. count .. " unique backups from index")
    else
        DCS_dprint("[DCS] init: No backup index found, starting fresh")
    end

    local staleFiles = { "auto_backup.lua", "backup_index.txt", ".dcs_init_probe" }
    for _, staleName in ipairs(staleFiles) do
        local stalePath = "DailyChallengeSystem/" .. staleName
        local testReader = getFileReader(stalePath, false)
        if testReader then
            testReader:close()
            DCS_dprint("[DCS] init: STALE file detected at root level: " .. stalePath .. " — delete manually if desired")
        end
    end

    DCS_dprint("[DCS] init: knownBackups count: " .. #DCS_Backup.knownBackups)
end

_G.DCS_Backup = DCS_Backup

return DCS_Backup
