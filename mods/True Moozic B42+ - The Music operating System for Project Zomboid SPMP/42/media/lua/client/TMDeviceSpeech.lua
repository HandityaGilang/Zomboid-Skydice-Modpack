------------------------------------------------------------------------
-- TMDeviceSpeech: short floating status text, vanilla TV/radio style.
--
-- Two display modes:
--   * TMSpeech.say(character, text)  - overhead speech on the ACTING
--     player (uses the engine's own Say bubble).
--   * TMSpeech.sayAt / sayDevice     - text drawn in world space above a
--     PLACED device (jukebox, placed boombox/HiFi), since plain objects
--     have no Say. Rendered on OnPostUIDraw at the device's tile.
--
-- Also owns the MP handshake "wait cue": one CD-seek noise (TMCDSkip1-3)
-- played when the ready-check begins, cut off the moment the song starts.
------------------------------------------------------------------------

TMSpeech = TMSpeech or {}

-- startId of the playback session the LOCAL player just requested; used by
-- the tick engines to know which start belongs to "us" (stop the wait cue,
-- show "Playing ..." on the actor only).
TMSpeech.pendingCueStartId = nil

local entries = {}      -- "x:y:z" -> { text, x, y, z, expire }
local laterQueue = {}   -- { at, text, character | x,y,z }
local DURATION_MS = 3500
local FADE_MS = 600

local function nowMs()
    return (getTimestampMs and getTimestampMs()) or 0
end

-- Short display label for a media fullType ("Tsarcraft.CassetteXYZ" -> item
-- display name, falling back to the name part of the fullType).
function TMSpeech.mediaLabel(fullType)
    if not fullType then return "media" end
    local sm = getScriptManager and getScriptManager() or nil
    local scr = sm and sm.FindItem and sm:FindItem(tostring(fullType)) or nil
    if scr and scr.getDisplayName then
        local n = scr:getDisplayName()
        if n and n ~= "" then return n end
    end
    local s = tostring(fullType)
    return string.match(s, "%.(.+)$") or s
end

------------------------------------------------------------------------
-- Localized status lines. Keys live in IGUI_TMS_* (all 27 languages);
-- the EN table is the fallback when a translation file is missing.
------------------------------------------------------------------------
local EN = {
    Handshake = "Sending MP handshake...",
    Waiting   = "Waiting for players...",
    Playing   = "Playing %1",
    StopSend  = "Sending stop to server...",
    StopDone  = "Stopped - synced",
    Stopped   = "Stopped",
    PowerOn   = "Power ON",
    PowerOff  = "Power OFF",
    Insert    = "Inserting %1",
    Eject     = "Ejecting %1",
    Next      = "Next track...",
    Prev      = "Previous track...",
}

function TMSpeech.text(key, arg)
    local s = nil
    if getTextOrNull then s = getTextOrNull("IGUI_TMS_" .. tostring(key)) end
    s = s or EN[key] or tostring(key)
    if arg ~= nil then s = string.gsub(s, "%%1", tostring(arg)) end
    return s
end

function TMSpeech.say(character, text)
    if not character or not text then return end
    if character.Say then character:Say(tostring(text)) end
end

function TMSpeech.sayAt(x, y, z, text)
    if not x or not y or not text then return end
    local key = tostring(math.floor(x)) .. ":" .. tostring(math.floor(y)) .. ":" .. tostring(math.floor(z or 0))
    entries[key] = { text = tostring(text), x = x, y = y, z = z or 0, expire = nowMs() + DURATION_MS }
end

function TMSpeech.sayDevice(obj, text)
    if not obj or not text or not obj.getX then return end
    TMSpeech.sayAt(obj:getX() + 0.5, obj:getY() + 0.5, obj:getZ(), text)
end

function TMSpeech.sayLater(character, text, delayMs)
    if not character or not text then return end
    laterQueue[#laterQueue + 1] = { at = nowMs() + (delayMs or 900), character = character, text = text }
end

function TMSpeech.sayDeviceLater(obj, text, delayMs)
    if not obj or not text or not obj.getX then return end
    laterQueue[#laterQueue + 1] = {
        at = nowMs() + (delayMs or 900),
        x = obj:getX() + 0.5, y = obj:getY() + 0.5, z = obj:getZ(),
        text = text,
    }
end

------------------------------------------------------------------------
-- MP relay: player actions are announced to every nearby client. The
-- sender displays locally right away; the server re-broadcasts the
-- semantic KEY (+ optional arg) so each receiver renders it in their OWN
-- language. World-device "Playing" lines are NOT relayed - every client's
-- tick engine already draws those locally.
------------------------------------------------------------------------
local function relay(payload)
    if not isClient() then return end
    local p = getPlayer()
    if p then sendClientCommand(p, 'truemusic', 'speech', payload) end
end

-- Above the acting player (relayed; receivers put it over the actor's head).
function TMSpeech.announce(character, key, arg)
    TMSpeech.say(character, TMSpeech.text(key, arg))
    relay({ key = key, arg = arg })
end

-- Above a placed device (relayed; receivers draw at the device tile).
function TMSpeech.announceDevice(obj, key, arg)
    if not obj or not obj.getX then return end
    TMSpeech.sayDevice(obj, TMSpeech.text(key, arg))
    relay({ key = key, arg = arg, x = obj:getX() + 0.5, y = obj:getY() + 0.5, z = obj:getZ() })
end

function TMSpeech.announceLater(character, key, arg, delayMs)
    local d = delayMs or 900
    TMSpeech.sayLater(character, TMSpeech.text(key, arg), d)
    relay({ key = key, arg = arg, delay = d })
end

function TMSpeech.announceDeviceLater(obj, key, arg, delayMs)
    if not obj or not obj.getX then return end
    local d = delayMs or 900
    TMSpeech.sayDeviceLater(obj, TMSpeech.text(key, arg), d)
    relay({ key = key, arg = arg, delay = d, x = obj:getX() + 0.5, y = obj:getY() + 0.5, z = obj:getZ() })
end

local RELAY_DIST = 30

local function onSpeechServerCommand(module, command, args)
    if module ~= 'truemusic' or command ~= 'speech' then return end
    if not args or not args.key then return end
    local me = getPlayer()
    if not me then return end
    -- The sender already displayed this locally.
    if args.oid ~= nil and me.getOnlineID and args.oid == me:getOnlineID() then return end
    local txt = TMSpeech.text(args.key, args.arg)
    local delay = tonumber(args.delay) or 0
    if args.x and args.y then
        local dx, dy = args.x - me:getX(), args.y - me:getY()
        if dx * dx + dy * dy > RELAY_DIST * RELAY_DIST then return end
        if delay > 0 then
            laterQueue[#laterQueue + 1] = { at = nowMs() + delay, x = args.x, y = args.y, z = args.z or 0, text = txt }
        else
            TMSpeech.sayAt(args.x, args.y, args.z or 0, txt)
        end
    else
        local speaker = nil
        if args.oid ~= nil and getOnlinePlayers then
            local ops = getOnlinePlayers()
            for i = 0, ops:size() - 1 do
                local p = ops:get(i)
                if p and p.getOnlineID and p:getOnlineID() == args.oid then
                    speaker = p
                    break
                end
            end
        end
        if not speaker then return end
        local dx, dy = speaker:getX() - me:getX(), speaker:getY() - me:getY()
        if dx * dx + dy * dy > RELAY_DIST * RELAY_DIST then return end
        if delay > 0 then
            laterQueue[#laterQueue + 1] = { at = nowMs() + delay, character = speaker, text = txt }
        else
            TMSpeech.say(speaker, txt)
        end
    end
end

Events.OnServerCommand.Add(onSpeechServerCommand)

------------------------------------------------------------------------
-- Handshake wait cue: ONE CD-seek noise while the MP ready-check runs.
------------------------------------------------------------------------
local cue = nil   -- { emitter, handle }

function TMSpeech.startHandshakeCue(character)
    TMSpeech.stopHandshakeCue()
    if not character or not character.getEmitter then return end
    local emitter = character:getEmitter()
    if not emitter then return end
    local name = "TMCDSkip" .. tostring(ZombRand(3) + 1)
    local handle = nil
    if emitter.playSoundImpl then
        handle = emitter:playSoundImpl(name, character)
    elseif emitter.playSound then
        handle = emitter:playSound(name)
    end
    if handle and handle ~= 0 then
        cue = { emitter = emitter, handle = handle }
    end
end

function TMSpeech.stopHandshakeCue()
    if cue and cue.emitter and cue.handle then
        if cue.emitter.isPlaying and cue.emitter:isPlaying(cue.handle) then
            cue.emitter:stopSound(cue.handle)
        end
    end
    cue = nil
end

------------------------------------------------------------------------
-- World-space renderer for placed-device text.
------------------------------------------------------------------------
local function draw()
    local t = nowMs()

    if #laterQueue > 0 then
        local keep = {}
        for i = 1, #laterQueue do
            local q = laterQueue[i]
            if t >= q.at then
                if q.character then
                    TMSpeech.say(q.character, q.text)
                else
                    TMSpeech.sayAt(q.x, q.y, q.z, q.text)
                end
            else
                keep[#keep + 1] = q
            end
        end
        laterQueue = keep
    end

    if not getPlayer() then return end
    for key, e in pairs(entries) do
        if t >= e.expire then
            entries[key] = nil
        else
            local a = 1.0
            local remain = e.expire - t
            if remain < FADE_MS then a = remain / FADE_MS end
            local sx = isoToScreenX(0, e.x, e.y, e.z)
            -- Extra iso-z lifts the line above the device model.
            local sy = isoToScreenY(0, e.x, e.y, e.z + 1.4)
            getTextManager():DrawStringCentre(UIFont.Small, sx, sy, e.text, 0.55, 1.0, 0.65, a)
        end
    end
end

Events.OnPostUIDraw.Add(draw)
