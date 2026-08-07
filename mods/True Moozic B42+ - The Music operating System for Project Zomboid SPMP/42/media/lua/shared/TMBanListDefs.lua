-- TMBanListDefs.lua (shared)
-- BAN MUSIC LIST core: server-authoritative list of banned music media.
-- Banned songs cannot be inserted/played on ANY TrueMoozic device by regular
-- players. Admins / debug-mode players keep access while the "admin bypass"
-- toggle in the Ban Music List UI is enabled.
--
-- Storage: global ModData "trueMusicBanList" =
--   { banned = { [fullType] = true, ... }, bypass = true/false, rev = n }
-- The server owns the table; clients receive it via ModData transmit/request.
require "TCMusicDefenitions"

TMBanList = TMBanList or {}
TMBanList.MODDATA_KEY = "trueMusicBanList"

------------------------------------------------------------------------
-- Data access
------------------------------------------------------------------------

function TMBanList.getData()
    local d = ModData.getOrCreate(TMBanList.MODDATA_KEY)
    if d.banned == nil then d.banned = {} end
    if d.bypass == nil then d.bypass = true end
    return d
end

------------------------------------------------------------------------
-- Authority: admin access level or debug mode (SP debug / -debug MP).
------------------------------------------------------------------------

function TMBanList.isAuthorized(player)
    if getDebug and getDebug() then return true end
    if isAdmin and isAdmin() then return true end
    if isCoopHost and isCoopHost() then return true end
    return TMBanList.isPlayerAuthorized(player)
end

-- Player-object-only check (no local-context globals). The server MUST use
-- this to validate a remote sender: globals like isAdmin() describe the
-- LOCAL context, not the player who sent the command.
function TMBanList.isPlayerAuthorized(player)
    if player then
        if player.isAccessLevel then
            local ok, res = pcall(function()
                return player:isAccessLevel("Admin") or player:isAccessLevel("Moderator")
                    or player:isAccessLevel("GM") or player:isAccessLevel("Overseer")
            end)
            if ok and res then return true end
        end
        if player.getAccessLevel then
            local ok, lvl = pcall(function() return player:getAccessLevel() end)
            if ok and lvl then
                local a = string.lower(tostring(lvl))
                if a == "admin" or a == "moderator" or a == "gm" or a == "overseer" then
                    return true
                end
            end
        end
    end
    return false
end

------------------------------------------------------------------------
-- Name resolution: media names appear as FULL types (Tsarcraft.CassetteX)
-- and legacy SHORT types (CassetteX). Bans are stored by full type.
------------------------------------------------------------------------

local shortMap = nil

local function buildShortMap()
    shortMap = {}
    local sm = getScriptManager()
    local ok, all = pcall(function() return sm:getAllItems() end)
    if ok and all then
        for i = 0, all:size() - 1 do
            local script = all:get(i)
            if script and script.getFullName then
                local fn = script:getFullName()
                local shortName = string.match(fn, "%.([^%.]+)$") or fn
                if shortName and not shortMap[shortName] then
                    shortMap[shortName] = fn
                end
            end
        end
    end
end

function TMBanList.resolveFull(name)
    if not name then return nil end
    local s = tostring(name)
    if string.find(s, "%.") then return s end
    local guess = "Tsarcraft." .. s
    if getScriptManager():FindItem(guess) then return guess end
    if not shortMap then buildShortMap() end
    return shortMap[s]
end

------------------------------------------------------------------------
-- Ban checks
------------------------------------------------------------------------

function TMBanList.isBannedName(name)
    if not name then return false end
    local banned = TMBanList.getData().banned
    if not banned then return false end
    local s = tostring(name)
    if banned[s] then return true end
    local full = TMBanList.resolveFull(s)
    if full and banned[full] then return true end
    return false
end

function TMBanList.isBannedItem(item)
    if not item or not item.getFullType then return false end
    return TMBanList.isBannedName(item:getFullType())
end

-- True when the player may use this media name (not banned, or the player
-- is admin/debug while the bypass toggle is on).
function TMBanList.canUseName(player, name)
    if not TMBanList.isBannedName(name) then return true end
    if TMBanList.getData().bypass and TMBanList.isAuthorized(player) then
        return true
    end
    return false
end

function TMBanList.canUseItem(player, item)
    if not item or not item.getFullType then return true end
    return TMBanList.canUseName(player, item:getFullType())
end

-- Throttled feedback when an interaction is blocked.
local lastNoteMs = 0
function TMBanList.blockNote(player)
    if not player or not player.setHaloNote then return end
    local now = (getTimestampMs and getTimestampMs()) or 0
    if now - lastNoteMs < 1500 then return end
    lastNoteMs = now
    player:setHaloNote(getText("IGUI_TMBan_Blocked"), 255, 70, 70, 300)
end

------------------------------------------------------------------------
-- Catalog: every music media item loaded on this game (base + all addon
-- packs), grouped per addon module.
--   entry = { fullType, shortType, display, kind }  kind: cassette|vinyl|cd
--   returns { order = {module1, module2, ...}, byModule = { [mod] = {entries} } }
------------------------------------------------------------------------

function TMBanList.buildCatalog()
    local byModule = {}
    local sm = getScriptManager()
    local ok, all = pcall(function() return sm:getAllItems() end)
    if ok and all then
        for i = 0, all:size() - 1 do
            local script = all:get(i)
            if script and script.getFullName then
                local full = script:getFullName()
                local module = string.match(full, "^([^%.]+)%.") or "?"
                local short = string.match(full, "%.([^%.]+)$") or full
                local kind = nil
                if SWTCCDAlbums and SWTCCDAlbums[short] then
                    kind = "cd"
                elseif GlobalMusic and GlobalMusic[short] then
                    kind = string.find(string.lower(short), "vinyl", 1, true) and "vinyl" or "cassette"
                end
                if kind then
                    local display = short
                    pcall(function()
                        if script.getDisplayName and script:getDisplayName() then
                            display = script:getDisplayName()
                        end
                    end)
                    byModule[module] = byModule[module] or {}
                    table.insert(byModule[module], {
                        fullType = full,
                        shortType = short,
                        display = display,
                        kind = kind,
                    })
                end
            end
        end
    end
    local order = {}
    for module, entries in pairs(byModule) do
        table.sort(entries, function(a, b) return tostring(a.display) < tostring(b.display) end)
        table.insert(order, module)
    end
    table.sort(order)
    return { order = order, byModule = byModule }
end

------------------------------------------------------------------------
-- Jukebox enforcement (shared: also runs on the server, which validates
-- container transfers). The jukebox has no acting-player context here, so
-- banned media is blocked in the jukebox for EVERYONE - admins can still
-- unban it from the Ban Music List UI.
------------------------------------------------------------------------

local function installJukeboxHooks()
    if TMBanList._jukeboxHooked then return end
    if not TMJukebox or not TMJukebox.isPlayableMedia or not TMJukebox.buildPlaylist then return end

    local origIsPlayable = TMJukebox.isPlayableMedia
    TMJukebox.isPlayableMedia = function(item)
        if TMBanList.isBannedItem(item) then return false end
        return origIsPlayable(item)
    end

    local origBuild = TMJukebox.buildPlaylist
    TMJukebox.buildPlaylist = function(obj)
        local playlist = origBuild(obj)
        local banned = TMBanList.getData().banned
        local bannedSounds = nil
        for full in pairs(banned) do
            bannedSounds = bannedSounds or {}
            local short = string.match(tostring(full), "%.([^%.]+)$") or tostring(full)
            local album = SWTCCDAlbums and SWTCCDAlbums[short] or nil
            if album and album.tracks then
                for t = 1, #album.tracks do
                    local track = album.tracks[t]
                    if track and track.soundName then
                        bannedSounds[track.soundName] = true
                    end
                end
            else
                bannedSounds[short] = true
            end
        end
        if not bannedSounds then return playlist end
        local out = {}
        for i = 1, #playlist do
            if not bannedSounds[playlist[i].soundName] then
                out[#out + 1] = playlist[i]
            end
        end
        return out
    end

    TMBanList._jukeboxHooked = true
end

Events.OnGameBoot.Add(installJukeboxHooks)
Events.OnGameStart.Add(installJukeboxHooks)

------------------------------------------------------------------------
-- ModData plumbing
------------------------------------------------------------------------

Events.OnInitGlobalModData.Add(function()
    TMBanList.getData()
end)

Events.OnReceiveGlobalModData.Add(function(key, packet)
    if key ~= TMBanList.MODDATA_KEY then return end
    if not packet then return end
    ModData.add(key, packet)
end)

Events.OnGameStart.Add(function()
    if isClient() then
        ModData.request(TMBanList.MODDATA_KEY)
    end
end)
