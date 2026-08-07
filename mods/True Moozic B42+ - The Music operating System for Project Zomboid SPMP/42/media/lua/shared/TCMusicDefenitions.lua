require "TCKeyBinding"
-- NOTE: do NOT require "TCStartWithDevice" here. It lives in lua/server/,
-- and during the shared-lua load phase the server file list isn't registered
-- yet, so the require fails with a WARN on dedicated servers. The server
-- files (TCServerCommands / TCSpawnController) require it themselves during
-- the server phase, where it resolves fine.

local DEBUG = false

if not TCMusic then TCMusic = {} end

-- Trait check that works for both vanilla and mod traits in B42.17+.
-- player:HasTrait(string) no longer exists; player:hasTrait(obj) needs the
-- CharacterTrait registry object: mod traits live in <Module>Registries
-- (ours: TrueMoozicRegistries.truemoozicfan), vanilla ones are CharacterTrait
-- statics (CharacterTrait.DEAF / HARD_OF_HEARING). Known-traits string scan
-- is the last-resort fallback.
function TCMusic.playerHasTrait(player, name)
    if not player or not name then return false end
    local obj = nil
    local reg = TrueMoozicRegistries
    if reg then obj = reg[name] or reg[string.lower(name)] end
    if not obj and CharacterTrait then
        -- CamelCase -> UPPER_SNAKE (HardOfHearing -> HARD_OF_HEARING)
        obj = CharacterTrait[string.upper((string.gsub(name, "(%l)(%u)", "%1_%2")))]
    end
    if obj then
        return player:hasTrait(obj) or false
    end
    local ct = player.getCharacterTraits and player:getCharacterTraits() or nil
    local list = ct and ct.getKnownTraits and ct:getKnownTraits() or nil
    if list then
        local lname = string.lower(name)
        for i = 0, list:size() - 1 do
            local t = list:get(i)
            if t then
                -- tostring(trait) is the full "module:name"; match either the
                -- full id or just the name part after the colon.
                local full = string.lower(tostring(t))
                local path = string.match(full, ":(.+)$") or full
                if full == lname or path == lname then return true end
            end
        end
    end
    return false
end

if (TCMusic.ItemMusicPlayer == nil) then TCMusic.ItemMusicPlayer = {} end
if (TCMusic.VehicleMusicPlayer == nil) then TCMusic.VehicleMusicPlayer = {} end
if (TCMusic.WorldMusicPlayer == nil) then TCMusic.WorldMusicPlayer = {} end
if (TCMusic.WalkmanPlayer == nil) then TCMusic.WalkmanPlayer = {} end
if (GlobalMusic == nil) then GlobalMusic = {} end

if DEBUG then
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoombox"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxBlue"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxCamo"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxBlack"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxGreen"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxPink"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxRed"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_34"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_35"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_62"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_36"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_37"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_63"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoombox"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxBlue"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxCamo"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxBlack"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxGreen"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxPink"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxRed"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCVinylplayer"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCVinylplayerBlack"] = "TrueMoozic_music_01_36"
    TCMusic.VehicleMusicPlayer["Base.HamRadio1"] = "TrueMoozic_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.HamRadio2"] = "TrueMoozic_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.RadioBlack"] = "TrueMoozic_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.RadioRed"] = "TrueMoozic_music_01_35"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkman"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanPurple"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanRed"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanBlack"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanPink"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanGreen"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanCamoGreen"] = "TrueMoozic_music_01_62"
else
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxBlue"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxCamo"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxBlack"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxGreen"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxPink"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxRed"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_34"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_35"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_62"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_36"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_37"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_63"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxBlue"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxCamo"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxBlack"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxGreen"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxPink"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxRed"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayerBlack"] = "tsarcraft_music_01_63"
    TCMusic.VehicleMusicPlayer["Base.HamRadio1"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.HamRadio2"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.RadioBlack"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.RadioRed"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkman"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanPurple"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanRed"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanBlack"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanPink"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanGreen"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanCamoGreen"] = "tsarcraft_music_01_62"
end

GlobalMusic["CassetteMainTheme"] = "tsarcraft_music_01_62"
GlobalMusic["VinylMainTheme"] = "tsarcraft_music_01_63"

-- Alias actual lowercase proxy sprite names used by world IsoRadio objects.
TCMusic.WorldMusicPlayer["tsarcraft_music_01_62"] = "tsarcraft_music_01_62"
TCMusic.WorldMusicPlayer["tsarcraft_music_01_63"] = "tsarcraft_music_01_63"

------------------------------------------------------------
-- Server-authoritative now_play sync (B42.20 MP)
--
-- Clients must NOT call ModData.transmit("trueMusicData"): a client transmit
-- pushes that client's whole (possibly stale) table to the server, clobbering
-- rows written by other players (this is why held boomboxes were silent for
-- everyone else while car radios — which use server commands — worked).
--
-- Instead, after mutating their OWN portable row locally, clients call
-- TCMusic.transmitNowPlay(character), which mirrors that row to the server via
-- the 'truemusic'/'setPortablePlayback' command. The server merges the row into
-- its authoritative table and broadcasts. World-device rows are already synced
-- through setWorldDeviceMedia/Volume/Playback commands.
------------------------------------------------------------
function TCMusic.getPortableMusicId(character)
    if not character then return nil end
    if character.getOnlineID then
        local id = tonumber(character:getOnlineID())
        if id and id > 0 then
            return id
        end
    end
    if character.getUsername then
        return character:getUsername()
    end
    return nil
end

------------------------------------------------------------
-- Synchronized start ("HEY EVERYONE, WE'RE PLAYING THIS NOW")
------------------------------------------------------------
-- When Play is pressed, the row is stamped with a unique startId and
-- broadcast to EVERY client immediately. Nobody (including the player who
-- pressed Play) starts the audio right away: everyone waits
-- SYNC_START_DELAY_MS from the moment the row was created, then starts the
-- track together. Far-away clients start it too (engine 3D / distance fade
-- keeps it at zero volume), so walking closer fades INTO a song that is
-- already at the correct position - no more "restarts from 0:00 when I get
-- near". The server ages row.timestamp, letting late receivers subtract the
-- time already elapsed so they still line up with everyone else.
TCMusic.SYNC_START_DELAY_MS = 2000

-- Sandbox toggle for the whole MP handshake (ready-check + shared delayed
-- start). Default OFF: play starts almost immediately; listeners sync by
-- joining the track mid-play (server-aged row timestamps).
function TCMusic.syncHandshakeEnabled()
    return (SandboxVars and SandboxVars.PZTrueMusicSandbox
        and SandboxVars.PZTrueMusicSandbox.MPSyncHandshake) == true
end

function TCMusic.newStartId(itemid)
    local ms = (getTimestampMs and getTimestampMs()) or 0
    return tostring(ms) .. ":" .. tostring(itemid or "x")
end

function TCMusic.transmitNowPlay(character)
    if isServer() then
        -- Server is the authority; broadcast directly.
        ModData.transmit("trueMusicData")
        return
    end
    if not isClient() then
        -- Singleplayer: the local table is the only copy; nothing to sync.
        return
    end
    if not character then return end
    local musicId = TCMusic.getPortableMusicId(character)
    if musicId == nil then return end
    local row = ModData.getOrCreate("trueMusicData")["now_play"][musicId]
    sendClientCommand(character, "truemusic", "setPortablePlayback", {
        isPlaying = row ~= nil,
        volume = row and row.volume or nil,
        headphone = row and row.headphone or false,
        musicName = row and row.musicName or nil,
        itemid = row and row.itemid or nil,
        startId = row and row.startId or nil,
    })
end

-- MP-safe wrapper for InventoryItem:syncItemFields(). Never sync an item
-- that lives inside another item's container (bag, CD case): the resulting
-- ItemStats packet's ContainerID can't be resolved by OTHER clients (they
-- don't have that bag's contents) and crashes their packet parser with
-- "containingItem is null", dropping item-sync packets for everyone nearby.
function TCMusic.safeSyncItem(item)
    if not isClient() then return end
    if not item or not item.syncItemFields then return end
    local cont = item.getContainer and item:getContainer() or nil
    if cont and cont.getContainingItem and cont:getContainingItem() ~= nil then return end
    item:syncItemFields()
end

------------------------------------------------------------
-- CD scratch system
------------------------------------------------------------
-- CDs looted OUTSIDE a CD case can be scratched (rolled at loot spawn).
-- Item modData:
--   TMScratch         = 25 | 50 | 75 | 100  (nil/absent = clean, no label)
--   TMScratchDelay    = seconds before a scratched track skips (3-10, rolled at spawn)
--   TMScratchSafeRoll = 0..0.999 float; picks the clean track(s) on 50%/75% CDs
-- Tier behaviour:
--   25%  : every 2nd track in the play order skips after TMScratchDelay seconds
--   50%  : every track EXCEPT one (fixed per CD) skips after TMScratchDelay seconds
--   75%  : one or two tracks (fixed per CD) play fully; the rest skip after 3-5 seconds
--   100% : every track skips after 0-1 seconds; the album does NOT loop and
--          playback stops after the last track.

function TCMusic.getScratchLabel(tier)
    if not tier or tier <= 0 then return nil end
    local word = (getTextOrNull and getTextOrNull("IGUI_TM_Scratched")) or "scratched"
    return " - " .. tostring(tier) .. "% " .. word
end

-- Next tier after one cleaning pass: 100 -> 75 -> 50 -> 25 -> 0 (clean).
function TCMusic.getNextScratchTier(tier)
    if not tier or tier <= 0 then return 0 end
    if tier > 75 then return 75 end
    if tier > 50 then return 50 end
    if tier > 25 then return 25 end
    return 0
end

-- Random scratch-skip sound effect name (TMCDSkip1/2/3).
function TCMusic.getRandomCDSkipSound()
    return "TMCDSkip" .. tostring(ZombRand(3) + 1)
end

-- True when the item is a scratchable CD album (mod CDs, not players/cases).
function TCMusic.isScratchableCDItem(item)
    if not item or not instanceof(item, "InventoryItem") then return false end
    local fullType = item.getFullType and item:getFullType() or nil
    if type(fullType) ~= "string" then return false end
    local module, typeName = string.match(fullType, "^([^%.]+)%.(.+)$")
    if not module or module == "Base" then return false end
    local lower = string.lower(typeName)
    if string.find(lower, "cdplayer", 1, true) or string.find(lower, "cdcase", 1, true) or string.find(lower, "cdcarryingcase", 1, true) then
        return false
    end
    if string.sub(typeName, 1, 3) == "CD_" then return true end
    if string.len(typeName) > 2 and string.sub(typeName, -2) == "CD" then return true end
    return false
end

-- Tier after being stepped on: 0 -> 25 -> 50 -> 100 (75 also jumps to 100).
function TCMusic.getStompNextTier(tier)
    if not tier or tier <= 0 then return 25 end
    if tier <= 25 then return 50 end
    return 100
end

-- Snapshot a CD item's scratch state as a plain table (safe to store in
-- another item's modData, e.g. a CD case that deletes the CD item).
function TCMusic.captureScratchSnapshot(item)
    if not item then return nil end
    local md = item:getModData()
    if not md.TMScratchRolled and not md.TMScratch then return nil end
    return {
        tier = md.TMScratch,
        delay = md.TMScratchDelay,
        safeRoll = md.TMScratchSafeRoll,
    }
end

-- Restore a scratch snapshot onto a freshly-created CD item (case take-out):
-- reapplies modData, the "- X% scratched" name label and the tooltip. Always
-- marks the CD as rolled so loot control never re-rolls a case-stored CD.
function TCMusic.applyScratchSnapshot(item, snap)
    if not item then return end
    local md = item:getModData()
    md.TMScratchRolled = true
    if snap and snap.tier and snap.tier > 0 then
        md.TMScratch = snap.tier
        md.TMScratchDelay = snap.delay
        md.TMScratchSafeRoll = snap.safeRoll
        TCMusic.applyScratchLabel(item)
    end
    TCMusic.applyScratchTooltip(item)
end

-- Sets/clears the hover tooltip that explains how to clean a scratched CD.
function TCMusic.applyScratchTooltip(item)
    if not item or not item.setTooltip then return end
    local md = item:getModData()
    if md.TMScratch and md.TMScratch > 0 then
        item:setTooltip("Tooltip_TM_CD_Scratched")
    else
        item:setTooltip(nil)
    end
end

-- Appends the "- X% scratched" suffix to the item name (once).
function TCMusic.applyScratchLabel(item)
    if not item then return end
    local md = item:getModData()
    local tier = md.TMScratch
    if not tier or tier <= 0 then return end
    TCMusic.applyScratchTooltip(item)
    if md.TMScratchLabeled then return end
    local label = TCMusic.getScratchLabel(tier)
    if label then
        item:setName(item:getName() .. label)
        md.TMScratchLabeled = true
    end
end

-- Copies the CD item's scratch state onto a device table (customMusic / hifiCD)
-- when the CD is inserted.
function TCMusic.copyScratchToDevice(deviceTable, item)
    if not deviceTable or not item then return end
    local md = item:getModData()
    deviceTable.scratch = md.TMScratch
    deviceTable.scratchDelay = md.TMScratchDelay
    deviceTable.scratchSafeRoll = md.TMScratchSafeRoll
end

-- Restores scratch state (modData + name label) onto the freshly-recreated CD
-- item on eject, so scratches survive the insert/eject round trip.
function TCMusic.restoreScratchToItem(item, deviceTable)
    if not item or not deviceTable then return end
    if not deviceTable.scratch or deviceTable.scratch <= 0 then return end
    local md = item:getModData()
    md.TMScratchRolled = true
    md.TMScratch = deviceTable.scratch
    md.TMScratchDelay = deviceTable.scratchDelay
    md.TMScratchSafeRoll = deviceTable.scratchSafeRoll
    TCMusic.applyScratchLabel(item)
    TCMusic.safeSyncItem(item)
end

function TCMusic.clearScratchOnDevice(deviceTable)
    if not deviceTable then return end
    deviceTable.scratch = nil
    deviceTable.scratchDelay = nil
    deviceTable.scratchSafeRoll = nil
end

-- Dev/admin tool: set (25/50/75/100) or clear (nil/0) the scratch tier on a CD
-- item, re-rolling the skip delay / safe track and fixing up the name label.
-- noSync: skip syncItemFields (for world items on the ground, where the item
-- isn't in a player inventory and the server applies its own copy).
function TCMusic.setScratchTier(item, tier, noSync)
    if not item then return end
    local md = item:getModData()
    -- Strip the existing "- X% scratched" suffix, if any.
    if md.TMScratchLabeled and md.TMScratch then
        local old = TCMusic.getScratchLabel(md.TMScratch)
        local name = item:getName()
        if old and name and #name > #old and string.sub(name, -#old) == old then
            item:setName(string.sub(name, 1, #name - #old))
        end
    end
    md.TMScratchLabeled = nil
    md.TMScratchRolled = true
    if tier and tier > 0 then
        md.TMScratch = tier
        md.TMScratchDelay = 3 + ZombRand(8)
        md.TMScratchSafeRoll = ZombRand(1000) / 1000
        TCMusic.applyScratchLabel(item)
    else
        md.TMScratch = nil
        md.TMScratchDelay = nil
        md.TMScratchSafeRoll = nil
    end
    TCMusic.applyScratchTooltip(item)
    if not noSync then TCMusic.safeSyncItem(item) end
end

-- Returns how many seconds into the given track the CD should force-skip,
-- or nil if this track plays through cleanly.
function TCMusic.getScratchSkipDelay(deviceTable, trackIndex, totalTracks)
    if not deviceTable or not deviceTable.scratch then return nil end
    local tier = deviceTable.scratch
    if tier == 25 then
        -- Every 2nd track in the order.
        if trackIndex and trackIndex % 2 == 0 then
            return deviceTable.scratchDelay or (3 + ZombRand(8))
        end
        return nil
    elseif tier == 50 then
        -- Every track except the one safe track picked at spawn.
        local total = totalTracks or 1
        local roll = deviceTable.scratchSafeRoll or 0
        local safe = math.floor(roll * total) + 1
        if safe > total then safe = total end
        if trackIndex ~= safe then
            return deviceTable.scratchDelay or (3 + ZombRand(8))
        end
        return nil
    elseif tier == 75 then
        -- One or two safe tracks (fixed per CD) play fully; the rest skip after 3-5s.
        local total = totalTracks or 1
        local roll = deviceTable.scratchSafeRoll or 0
        local safe1 = math.floor(roll * total) + 1
        if safe1 > total then safe1 = total end
        local safe2 = nil
        local roll2 = (roll * 7919) % 1 -- second deterministic roll derived from the first
        if total >= 3 and roll2 >= 0.5 then
            safe2 = math.floor(roll2 * total) + 1
            if safe2 > total then safe2 = total end
            if safe2 == safe1 then
                safe2 = (safe2 % total) + 1
            end
        end
        if trackIndex == safe1 or trackIndex == safe2 then
            return nil
        end
        return 3 + ZombRand(3) -- 3-5 seconds, rerolled per track
    elseif tier == 100 then
        -- Every track, 0-1 seconds, rerolled per track.
        return ZombRand(1001) / 1000
    end
    return nil
end

-- 100% scratched CDs don't loop: playback stops after the last track.
function TCMusic.isScratchNoLoop(deviceTable)
    if deviceTable and deviceTable.scratch == 100 then return true end
    return false
end


