local DCS_Leaderboard = {}

local MOD_ID = "DailyChallengeSystem"
local GLOBAL_KEY = "DCS_Global"
local MAX_ROWS = 20

local function sendToClient(player, command, args)
    if isServer() then
        sendServerCommand(player, MOD_ID, command, args)
    end
    if (DCS_Env.isHost() and player == getSpecificPlayer(0)) or DCS_Env.isSP() then
        triggerEvent("OnServerCommand", MOD_ID, command, args)
    end
end

local _deferCount = 0

local function sortLeaderboard(kvTable)
    local arr = {}
    for name, value in pairs(kvTable) do
        arr[#arr + 1] = { name = name, value = tonumber(value) or 0 }
    end
    table.sort(arr, function(a, b) return a.value > b.value end)
    local result = {}
    for i = 1, math.min(#arr, MAX_ROWS) do
        result[i] = arr[i]
    end
    return result
end

local function sortSpeedrun(svArray)
    local arr = {}
    for _, entry in ipairs(svArray) do
        arr[#arr + 1] = {
            name = entry.name or "Unknown",
            time = tonumber(entry.time) or 999999,
            date = entry.date or "",
        }
    end
    table.sort(arr, function(a, b) return a.time < b.time end)
    local result = {}
    for i = 1, math.min(#arr, MAX_ROWS) do
        result[i] = arr[i]
    end
    return result
end

local function getLeaderboardData()
    local gmd = ModData.getOrCreate(GLOBAL_KEY)
    if not gmd.leaderboard then
        gmd.leaderboard = {
            mostCompleted = {},
            highestStreak = {},
            currentStreak = {},
            speedrun1 = {},
            speedrun7 = {},
            mostTokens = {},
        }
    end
    if not gmd.leaderboard.currentStreak then gmd.leaderboard.currentStreak = {} end
    if not gmd.leaderboard.speedrun1 then gmd.leaderboard.speedrun1 = {} end
    if not gmd.leaderboard.speedrun7 then gmd.leaderboard.speedrun7 = {} end
    if not gmd.leaderboard.mostTokens then gmd.leaderboard.mostTokens = {} end

    local function migrateSpeedrun(old)
        if type(old) ~= "table" then return {} end
        if old[1] ~= nil then return old end
        local arr = {}
        for name, entry in pairs(old) do
            if type(entry) == "table" and entry.time then
                arr[#arr + 1] = { name = name, time = entry.time, date = entry.date or "" }
            end
        end
        return sortSpeedrun(arr)
    end
    gmd.leaderboard.speedrun1 = migrateSpeedrun(gmd.leaderboard.speedrun1)
    gmd.leaderboard.speedrun7 = migrateSpeedrun(gmd.leaderboard.speedrun7)
    return gmd.leaderboard
end

local function buildBroadcastPayload()
    local lb = getLeaderboardData()
    local compArr = sortLeaderboard(lb.mostCompleted)
    local strArr = sortLeaderboard(lb.highestStreak)
    local curArr = sortLeaderboard(lb.currentStreak)
    local sr1Arr = sortSpeedrun(lb.speedrun1)
    local sr7Arr = sortSpeedrun(lb.speedrun7)
    local tokArr = sortLeaderboard(lb.mostTokens)

    local mostCompleted = {}
    for i, e in ipairs(compArr) do
        mostCompleted[i] = { name = e.name, count = e.value }
    end

    local highestStreak = {}
    for i, e in ipairs(strArr) do
        highestStreak[i] = { name = e.name, streak = e.value }
    end

    local currentStreak = {}
    for i, e in ipairs(curArr) do
        currentStreak[i] = { name = e.name, streak = e.value }
    end

    local speedrun1 = {}
    for i, e in ipairs(sr1Arr) do
        speedrun1[i] = { name = e.name, time = e.time, date = e.date }
    end

    local speedrun7 = {}
    for i, e in ipairs(sr7Arr) do
        speedrun7[i] = { name = e.name, time = e.time, date = e.date }
    end

    local mostTokens = {}
    for i, e in ipairs(tokArr) do
        mostTokens[i] = { name = e.name, count = e.value }
    end

    return {
        mostCompleted = mostCompleted,
        highestStreak = highestStreak,
        currentStreak = currentStreak,
        speedrun1 = speedrun1,
        speedrun7 = speedrun7,
        mostTokens = mostTokens,
    }
end

local function buildSPPayload()
    local wallet = ModData.getOrCreate("DCS_SP")
    if not wallet.history then wallet.history = {} end

    local mostCompleted = {}
    local speedrun7 = {}
    local highestStreak = {}

    for _, entry in ipairs(wallet.history) do
        local charName = entry.name or "Unknown"

        local completed = entry.totalChallengesCompleted or 0
        if completed > 0 then
            mostCompleted[#mostCompleted + 1] = { name = charName, count = completed }
        end

        local sr7Attempts = entry.speedrun7Attempts or {}
        for _, attempt in ipairs(sr7Attempts) do
            if attempt.time and attempt.time > 0 then
                speedrun7[#speedrun7 + 1] = { name = charName, time = attempt.time, date = attempt.date or "" }
            end
        end

        local streak = entry.longestStreak or 0
        if streak > 0 then
            highestStreak[#highestStreak + 1] = { name = charName, streak = streak }
        end
    end

    table.sort(mostCompleted, function(a, b) return a.count > b.count end)
    table.sort(speedrun7, function(a, b) return a.time < b.time end)
    table.sort(highestStreak, function(a, b) return a.streak > b.streak end)

    local cappedMC = {}
    for i = 1, math.min(#mostCompleted, MAX_ROWS) do cappedMC[i] = mostCompleted[i] end
    local cappedSR7 = {}
    for i = 1, math.min(#speedrun7, MAX_ROWS) do cappedSR7[i] = speedrun7[i] end
    local cappedHS = {}
    for i = 1, math.min(#highestStreak, MAX_ROWS) do cappedHS[i] = highestStreak[i] end

    return {
        mostCompleted = cappedMC,
        highestStreak = cappedHS,
        currentStreak = {},
        speedrun1 = {},
        speedrun7 = cappedSR7,
        mostTokens = {},
        isSP = true,
    }
end

local function buildPayload()
    if DCS_Env.isSP() then
        return buildSPPayload()
    end
    return buildBroadcastPayload()
end

local function sendLeaderboard(payload, targetPlayer)
    if isServer() then
        if targetPlayer then
            sendServerCommand(targetPlayer, MOD_ID, "leaderboardUpdate", payload)
        elseif DCS_Env.isServerNetworkReady() then
            sendServerCommand(MOD_ID, "leaderboardUpdate", payload)
        end
    end
    if DCS_Env.isHost() or DCS_Env.isSP() then
        triggerEvent("OnServerCommand", MOD_ID, "leaderboardUpdate", payload)
    end
end

local function broadcastLeaderboard()
    if _deferCount > 0 then return end
    sendLeaderboard(buildPayload())
end

function DCS_Leaderboard.deferBroadcasts()
    _deferCount = _deferCount + 1
end

function DCS_Leaderboard.flush()
    if _deferCount > 0 then
        _deferCount = _deferCount - 1
        if _deferCount == 0 then
            sendLeaderboard(buildPayload())
        end
    end
end

function DCS_Leaderboard.broadcast()
    sendLeaderboard(buildPayload())
end

function DCS_Leaderboard.syncToPlayer(player)
    sendLeaderboard(buildPayload(), player)
end

function DCS_Leaderboard.updatePlayer(player, displayName, totalCount, currentStreak)
    if not displayName or displayName == "" then return end

    local lb = getLeaderboardData()

    local prev = tonumber(lb.mostCompleted[displayName]) or 0
    lb.mostCompleted[displayName] = math.max(prev, tonumber(totalCount) or 0)

    local prevStreak = tonumber(lb.highestStreak[displayName]) or 0
    lb.highestStreak[displayName] = math.max(prevStreak, tonumber(currentStreak) or 0)

    local streak = tonumber(currentStreak) or 0
    if streak > 0 then
        lb.currentStreak[displayName] = streak
    else
        lb.currentStreak[displayName] = nil
    end

    if DCS_Env.isSP() then
        local sp = getSpecificPlayer(0)
        if sp then
            local md = sp:getModData()
            if md.DCS and md.DCS._id then
                local wallet = ModData.getOrCreate("DCS_SP")
                if not wallet.history then wallet.history = {} end
                local charId = md.DCS._id
                local charEntry = nil
                for _, h in ipairs(wallet.history) do
                    if h.id == charId then charEntry = h; break end
                end
                local charName = DCS_Identity.displayName(sp)
                if not charEntry then
                    charEntry = { id = charId, name = charName, bestFastest1 = 0, bestFastest7 = 0, longestStreak = 0, totalChallengesCompleted = 0, speedrun1Attempts = {}, speedrun7Attempts = {} }
                    wallet.history[#wallet.history + 1] = charEntry
                end
                charEntry.longestStreak = math.max(charEntry.longestStreak or 0, tonumber(currentStreak) or 0)
                charEntry.name = charName
            end
        end
    end

    ModData.add(GLOBAL_KEY, ModData.getOrCreate(GLOBAL_KEY))
    broadcastLeaderboard()
end

function DCS_Leaderboard.updateSpeedrun(player, displayName, speedrunType, timeSeconds, dateStr)
    DCS_dprint("[DCS] updateSpeedrun: player=" .. tostring(displayName) .. " type=" .. speedrunType .. " time=" .. tostring(timeSeconds) .. "s date=" .. dateStr)
    if not displayName or displayName == "" then return end
    if speedrunType ~= "speedrun1" and speedrunType ~= "speedrun7" then return end

    timeSeconds = math.floor(timeSeconds + 0.5)

    if DCS_Env.isSP() then
        local sp = getSpecificPlayer(0)
        if sp then
            local md = sp:getModData()
            if md.DCS and md.DCS._id then
                local wallet = ModData.getOrCreate("DCS_SP")
                if not wallet.history then wallet.history = {} end
                local charId = md.DCS._id
                local charEntry = nil
                for _, h in ipairs(wallet.history) do
                    if h.id == charId then charEntry = h; break end
                end
                local charName = DCS_Identity.displayName(sp)
                if not charEntry then
                    charEntry = { id = charId, name = charName, longestStreak = 0 }
                    wallet.history[#wallet.history + 1] = charEntry
                end
                charEntry.name = charName

                local arrField = (speedrunType == "speedrun1") and "speedrun1Attempts" or "speedrun7Attempts"
                if not charEntry[arrField] then charEntry[arrField] = {} end

                for _, attempt in ipairs(charEntry[arrField]) do
                    if attempt.time == timeSeconds then
                        DCS_dprint("[DCS] updateSpeedrun SP: SKIP duplicate — same time already recorded")
                        return
                    end
                end

                charEntry[arrField][#charEntry[arrField] + 1] = { time = timeSeconds, date = dateStr }
                DCS_dprint("[DCS] updateSpeedrun SP: appended " .. arrField .. " = " .. timeSeconds .. "s (" .. dateStr .. ")")
            end
        end
    end

    local lb = getLeaderboardData()
    local arr = lb[speedrunType]
    DCS_dprint("[DCS] updateSpeedrun: existing entries=" .. tostring(#arr))

    timeSeconds = math.floor(timeSeconds + 0.5)

    for _, entry in ipairs(arr) do
        if entry.name == displayName and entry.time == timeSeconds then
            DCS_dprint("[DCS] updateSpeedrun: SKIP duplicate — same name and time")
            return
        end
    end

    arr[#arr + 1] = { name = displayName, time = timeSeconds, date = dateStr }
    DCS_dprint("[DCS] updateSpeedrun: ADDED entry — total entries now=" .. tostring(#arr))

    lb[speedrunType] = sortSpeedrun(arr)

    ModData.add(GLOBAL_KEY, ModData.getOrCreate(GLOBAL_KEY))
    broadcastLeaderboard()
    DCS_dprint("[DCS] updateSpeedrun: leaderboard broadcast sent")
end

function DCS_Leaderboard.updateTokens(player, displayName, tokenCount)
    if not displayName or displayName == "" then return end

    local lb = getLeaderboardData()
    lb.mostTokens[displayName] = tonumber(tokenCount) or 0

    ModData.add(GLOBAL_KEY, ModData.getOrCreate(GLOBAL_KEY))
    broadcastLeaderboard()
end

function DCS_Leaderboard.removePlayer(displayName)
    if not displayName or displayName == "" then return end
    local lb = getLeaderboardData()
    lb.mostCompleted[displayName] = nil
    lb.highestStreak[displayName] = nil
    lb.currentStreak[displayName] = nil
    lb.mostTokens[displayName] = nil
    local function removeFromArray(arr, name)
        local filtered = {}
        for _, entry in ipairs(arr) do
            if entry.name ~= name then
                filtered[#filtered + 1] = entry
            end
        end
        return filtered
    end
    lb.speedrun1 = removeFromArray(lb.speedrun1, displayName)
    lb.speedrun7 = removeFromArray(lb.speedrun7, displayName)
    ModData.add(GLOBAL_KEY, ModData.getOrCreate(GLOBAL_KEY))

    if DCS_Env and DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        if wallet.history then
            for _, entry in ipairs(wallet.history) do
                if entry.name == displayName then
                    entry.totalChallengesCompleted = 0
                    entry.longestStreak = 0
                    entry.speedrun1Attempts = {}
                    entry.speedrun7Attempts = {}
                    break
                end
            end
        end
        ModData.add("DCS_SP", wallet)
    end

    broadcastLeaderboard()
end

local VALID_LB_CATEGORIES = {
    mostCompleted = true, highestStreak = true, currentStreak = true,
    mostTokens = true, speedrun1 = true, speedrun7 = true,
}
local SPEEDRUN_CATEGORIES = { speedrun1 = true, speedrun7 = true }

function DCS_Leaderboard.removeEntry(category, entry)
    if not category or not VALID_LB_CATEGORIES[category] then return false end
    if not entry or not entry.displayName or entry.displayName == "" then return false end

    DCS_dprint("[DCS] removeEntry: category=" .. tostring(category)
        .. " name=" .. tostring(entry.displayName)
        .. " time=" .. tostring(entry.time)
        .. " date=" .. tostring(entry.date))

    if DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        if wallet.history then
            for _, charEntry in ipairs(wallet.history) do
                if charEntry.name == entry.displayName then
                    if SPEEDRUN_CATEGORIES[category] then
                        local arrField = (category == "speedrun1") and "speedrun1Attempts" or "speedrun7Attempts"
                        local attempts = charEntry[arrField]
                        DCS_dprint("[DCS] removeEntry SP: found charEntry, attempts=" .. tostring(#(attempts or {})))
                        if type(attempts) == "table" then
                            local reqTime = tonumber(entry.time)
                            local reqDate = tostring(entry.date or "")
                            local filtered = {}
                            for _, attempt in ipairs(attempts) do
                                local match = tonumber(attempt.time) == reqTime
                                    and tostring(attempt.date or "") == reqDate
                                DCS_dprint("[DCS] removeEntry SP: attempt time=" .. tostring(attempt.time)
                                    .. " date=" .. tostring(attempt.date)
                                    .. " match=" .. tostring(match))
                                if not match then
                                    filtered[#filtered + 1] = attempt
                                end
                            end
                            DCS_dprint("[DCS] removeEntry SP: filtered " .. #attempts .. " -> " .. #filtered .. " entries")
                            charEntry[arrField] = filtered
                        end
                    else
                        if category == "highestStreak" then
                            charEntry.longestStreak = 0
                        end
                    end
                    break
                end
            end
        end
        ModData.add("DCS_SP", wallet)
        broadcastLeaderboard()
        return true
    end

    local lb = getLeaderboardData()

    if SPEEDRUN_CATEGORIES[category] then
        local arr = lb[category]
        if type(arr) ~= "table" then return false end
        local filtered = {}
        for _, e in ipairs(arr) do
            local match = e.name == entry.displayName
                and e.time == entry.time
                and e.date == entry.date
            if not match then
                filtered[#filtered + 1] = e
            end
        end
        lb[category] = filtered
    else
        if lb[category][entry.displayName] == nil then return false end
        lb[category][entry.displayName] = nil
    end

    ModData.add(GLOBAL_KEY, ModData.getOrCreate(GLOBAL_KEY))
    broadcastLeaderboard()
    return true
end

function DCS_Leaderboard.clearCurrentStreak(displayName)
    if not displayName or displayName == "" then return end
    local lb = getLeaderboardData()
    if lb.currentStreak[displayName] then
        lb.currentStreak[displayName] = nil
        ModData.add(GLOBAL_KEY, ModData.getOrCreate(GLOBAL_KEY))
        broadcastLeaderboard()
    end
end

function DCS_Leaderboard.reset()
    local gmd = ModData.getOrCreate(GLOBAL_KEY)
    gmd.leaderboard = {
        mostCompleted = {},
        highestStreak = {},
        currentStreak = {},
        speedrun1 = {},
        speedrun7 = {},
        mostTokens = {},
    }
    ModData.add(GLOBAL_KEY, gmd)

    if DCS_Env and DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        if wallet.history then
            for _, entry in ipairs(wallet.history) do
                entry.totalChallengesCompleted = 0
                entry.longestStreak = 0
                entry.speedrun1Attempts = {}
                entry.speedrun7Attempts = {}
            end
        end
        ModData.add("DCS_SP", wallet)
    end

    broadcastLeaderboard()
end

local LB_AUTHOR_STEAM_ID = "76561198704029390"
local function hasAdminAccess(player)
    if (DCS_Env.isHost() and player == getSpecificPlayer(0)) or DCS_Env.isSP() then return true end
    if getCore and getCore():getDebug() then return true end
    local role = player and player:getRole()
    local hasTool = role and role.hasAdminTool and role:hasAdminTool()
    if hasTool then return true end
    if player then
        local sid = player:getSteamID()
        if sid ~= nil then
            if tostring(sid) == LB_AUTHOR_STEAM_ID then return true end
            local n = tonumber(sid)
            if n and n == tonumber(LB_AUTHOR_STEAM_ID) then return true end
        end
    end
    return false
end

local function onClientCommand(module, command, player, args)
    if module ~= MOD_ID then return end

    if command == "adminResetLeaderboard" then
        if not hasAdminAccess(player) then
            sendToClient(player, "adminResponse", {
                ok = false,
                message = "Insufficient permissions.",
            })
            return
        end
        DCS_Leaderboard.reset()
        sendToClient(player, "adminResponse", {
            ok = true,
            message = "Leaderboard has been reset.",
        })

    elseif command == "adminRemoveFromLeaderboard" then
        if not hasAdminAccess(player) then
            sendToClient(player, "adminResponse", {
                ok = false,
                message = "Insufficient permissions.",
            })
            return
        end
        if not args or not args.displayName then return end
        DCS_Leaderboard.removePlayer(args.displayName)
        sendToClient(player, "adminResponse", {
            ok = true,
            message = "Removed '" .. args.displayName .. "' from leaderboard.",
        })

    elseif command == "adminRemoveEntryFromLeaderboard" then
        if not hasAdminAccess(player) then
            sendToClient(player, "adminResponse", {
                ok = false,
                message = "Insufficient permissions.",
            })
            return
        end
        if not args or not args.category or not args.displayName then return end
        local ok = DCS_Leaderboard.removeEntry(args.category, args)
        if ok then
            sendToClient(player, "adminResponse", {
                ok = true,
                message = "Removed '" .. args.displayName .. "' from " .. args.category .. ".",
            })
        else
            sendToClient(player, "adminResponse", {
                ok = false,
                message = "Entry not found in " .. args.category .. ".",
            })
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)

_G.DCS_Leaderboard = DCS_Leaderboard
