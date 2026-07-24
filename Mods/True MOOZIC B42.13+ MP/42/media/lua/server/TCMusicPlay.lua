
if isClient() then return end

local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end
local PROBE = false
local function probe(msg)
    if PROBE then
        print("[TMDBG][TickServer] " .. tostring(msg))
    end
end

local tickControl = 50
local tickStart = 0
local RADIUS = 25
local realDeltaAccum = 0
local playClock = {}

local function normalizeWorldNowPlayCanonical(nowPlay)
    if not nowPlay then return end

    local canonicalByItemId = {}
    local additions = {}
    local removals = {}

    for id, row in pairs(nowPlay) do
        local musicId = tostring(id)
        if string.match(musicId, '^W:') then
            local rid = (row and (row["itemid"] or row["radioItemID"])) or string.sub(musicId, 3)
            if rid ~= nil and tostring(rid) ~= "" then
                canonicalByItemId[tostring(rid)] = musicId
            end
        end
    end

    for id, row in pairs(nowPlay) do
        local musicId = tostring(id)
        if string.match(musicId, '^#') then
            local rid = row and (row["itemid"] or row["radioItemID"]) or nil
            if rid ~= nil and tostring(rid) ~= "" then
                local ridKey = tostring(rid)
                local canonicalId = canonicalByItemId[ridKey]
                if not canonicalId then
                    canonicalId = "W:" .. ridKey
                    canonicalByItemId[ridKey] = canonicalId
                end

                if canonicalId ~= musicId then
                    local existing = nowPlay[canonicalId] or additions[canonicalId]
                    if not existing then
                        additions[canonicalId] = row
                    end
                    removals[musicId] = true
                end
            end
        end
    end

    for id, _ in pairs(removals) do
        nowPlay[id] = nil
        probe("normalize now_play removed-legacy key=" .. tostring(id))
    end

    for id, row in pairs(additions) do
        row["itemid"] = row["itemid"] or row["radioItemID"] or string.sub(tostring(id), 3)
        nowPlay[id] = row
        probe("normalize now_play added-canonical key=" .. tostring(id))
    end
end

local function getWorldCoordsFromNowPlayEntry(musicId, data)
    local x, y, z = string.match(tostring(musicId), '^#(%-?%d+)[-](%-?%d+)[-](%-?%d+)')
    if x then
        return tonumber(x), tonumber(y), tonumber(z)
    end
    if string.match(tostring(musicId), '^W:') and data then
        local dx = tonumber(data["x"])
        local dy = tonumber(data["y"])
        local dz = tonumber(data["z"])
        if dx and dy and dz then
            return dx, dy, dz
        end
    end
    return nil, nil, nil
end

local function worldSourceExists(data, x, y, z)
    local sq = getSquare(x, y, z)
    if not sq then
        return false
    end
    local wanted = data and data["itemid"] and tonumber(data["itemid"]) or nil
    local wantedRaw = data and data["itemid"] and tostring(data["itemid"]) or nil

    if wantedRaw and string.match(wantedRaw, '^J:') then
        
        return false
    end

    if wanted and sq.getWorldObjects then
        local worldObjects = sq:getWorldObjects()
        for i = 0, worldObjects:size() - 1 do
            local wObj = worldObjects:get(i)
            if wObj and instanceof(wObj, "IsoWorldInventoryObject") then
                local it = wObj:getItem()
                if it and it.getID and tonumber(it:getID()) == wanted then
                    return true
                end
            end
        end
        return false
    end

    -- Legacy recovery: resolve missing itemid via IsoRadio.RadioItemID.
    if sq.getObjects and sq.getWorldObjects then
        local objs = sq:getObjects()
        local worldObjects = sq:getWorldObjects()
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            if obj and instanceof(obj, "IsoRadio") then
                local md = obj.getModData and obj:getModData() or nil
                local tcm = md and md.tcmusic or nil
                if (not wanted) and wantedRaw and string.match(wantedRaw, '^J:') then
                    -- dead path: jukebox disabled
                end
                if (not wanted) and wantedRaw and string.match(wantedRaw, '^C:') then
                    return true
                end
                local rid = md and md.RadioItemID and tonumber(md.RadioItemID) or nil
                if rid then
                    for j = 0, worldObjects:size() - 1 do
                        local wObj = worldObjects:get(j)
                        if wObj and instanceof(wObj, "IsoWorldInventoryObject") then
                            local it = wObj:getItem()
                            if it and it.getID and tonumber(it:getID()) == rid then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function worldSourceIsActive(data, x, y, z)
    local sq = getSquare(x, y, z)
    if not sq or not sq.getObjects then
        return false
    end
    local wanted = data and data["itemid"] and tonumber(data["itemid"]) or nil
    local wantedRaw = data and data["itemid"] and tostring(data["itemid"]) or nil

    if wantedRaw and string.match(wantedRaw, '^J:') then
        
        return false
    end

    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if obj and instanceof(obj, "IsoRadio") then
            local md = obj.getModData and obj:getModData() or nil
            local rid = md and md.RadioItemID and tonumber(md.RadioItemID) or nil
            if (not wanted) or (rid and rid == wanted) then
                local tcm = md and md.tcmusic or nil
                if tcm and tcm.isPlaying then
                    return true
                end
            end
        end
    end
    return false
end

local function getTimeoutSeconds()
    local vars = SandboxVars and SandboxVars.PZTrueMusicSandbox
    local value = vars and vars.MusicPlaybackTimeoutSeconds
    if type(value) ~= "number" then
        return 2100
    end
    if value < 1 then
        return 1
    end
    return value
end

local function getRealSecondsDelta()
    local gt = getGameTime()
    if gt and gt.getRealworldSecondsSinceLastUpdate then
        local delta = gt:getRealworldSecondsSinceLastUpdate()
        if type(delta) == "number" and delta >= 0 then
            return delta
        end
    end
    return 0
end

local function getPlayerByMusicId(musicId)
    if not musicId then return nil end
    local onlineId = tonumber(musicId)
    if onlineId then
        local p = getPlayerByOnlineID(onlineId)
        if p then return p end
    end
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            if p and p.getUsername and p:getUsername() == tostring(musicId) then
                return p
            end
        end
    end
    for i = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(i)
        if p and p.getUsername and p:getUsername() == tostring(musicId) then
            return p
        end
    end
    return nil
end

function OnTickServerCheckMusic ()
    realDeltaAccum = realDeltaAccum + getRealSecondsDelta()
    tickStart = tickStart + 1
    if (tickStart % tickControl == 0) then
        tickStart = 0
        local deltaReal = realDeltaAccum
        realDeltaAccum = 0
        local musicData = ModData.getOrCreate("trueMusicData")
        if not musicData["now_play"] then
            musicData["now_play"] = {}
        end

        local nowPlay = musicData["now_play"]
        normalizeWorldNowPlayCanonical(nowPlay)
        local TIMEWAIT = getTimeoutSeconds()
        local seen = {}
        
        for musicId, data in pairs(nowPlay) do
            local volume = tonumber(data["volume"]) or 1
            if volume < 0 then volume = 0 end
            local timestamp = data["timestamp"]
            local headphone = data["headphone"]
            seen[musicId] = true
            
            if timestamp == "update" then
                local clock = playClock[musicId]
                local sameSource = false
                if clock then
                    sameSource = (clock.musicName == data["musicName"]) and (clock.itemid == data["itemid"])
                end
                if sameSource then
                    data["timestamp"] = clock.ts
                    timestamp = data["timestamp"]
                else
                    data["timestamp"] = 0
                    timestamp = 0
                end
            end
            
            if not data["startTime"] then
                data["startTime"] = timestamp
            end

            data["timestamp"] = (data["timestamp"] or 0) + deltaReal
            timestamp = data["timestamp"]
            playClock[musicId] = {
                ts = timestamp,
                musicName = data["musicName"],
                itemid = data["itemid"],
            }
            
            local skipNowPlay = false
            local x, y, z = getWorldCoordsFromNowPlayEntry(musicId, data)
            if x ~= nil then
                if not worldSourceExists(data, x, y, z) then
                    probe("clear now_play musicId=" .. tostring(musicId) .. " reason=missing-world-source")
                    ModData.get("trueMusicData")["now_play"][musicId] = nil
                    skipNowPlay = true
                elseif (timestamp or 0) > 2 and (not worldSourceIsActive(data, x, y, z)) then
                    probe("clear now_play musicId=" .. tostring(musicId) .. " reason=world-source-not-playing")
                    ModData.get("trueMusicData")["now_play"][musicId] = nil
                    skipNowPlay = true
                else
                    addSound(nil, x, y, z, RADIUS * volume, 1)
                end
            else
                local player = isServer() and getPlayerByMusicId(musicId) or getPlayer()
                if player then
                    if not headphone then
                        addSound(nil, player:getX(), player:getY(), player:getZ(), RADIUS * volume, 1)
                    end
                else
                    -- Username IDs can resolve late; let timeout handle cleanup.
                    probe("keep now_play musicId=" .. tostring(musicId) .. " reason=player-not-found")
                end
            end
            
            if (not skipNowPlay) and isServer() and timestamp > TIMEWAIT then
                probe("clear now_play musicId=" .. tostring(musicId) .. " reason=timeout ts=" .. tostring(timestamp) .. " limit=" .. tostring(TIMEWAIT))
                ModData.get("trueMusicData")["now_play"][musicId] = nil
            end
        end

        for musicId, _ in pairs(playClock) do
            if not seen[musicId] then
                playClock[musicId] = nil
            end
        end
    end
end

Events.OnTick.Add(OnTickServerCheckMusic)
dlog("TCMUSIC SERVER LOADING")




