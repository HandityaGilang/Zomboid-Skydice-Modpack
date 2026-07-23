LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.PersistenceSchema = LifestyleSecure.PersistenceSchema or {}

local Schema = LifestyleSecure.PersistenceSchema

Schema.schemaVersion = 1
Schema.NAMESPACE = "LifestyleSecure"
Schema.MAX_DEPTH = 6
Schema.MAX_TABLE_ENTRIES = 256
Schema.MAX_TOTAL_ENTRIES = 2048
Schema.MAX_STRING_LENGTH = 256
Schema.MAX_KEY_LENGTH = 64
Schema.MIN_NUMBER = -1000000000
Schema.MAX_NUMBER = 1000000000

Schema.playerKeys = {
    -- Needs and long-lived wellness state.
    hygieneNeed = true,
    hygieneNeedLimit = true,
    bathroomNeed = true,
    lastBath = true,
    lastBrushTeeth = true,
    lastCheckYourself = true,
    ComfortNeed = true,
    ComfortVal = true,
    BeautyNeed = true,
    IsMeditationMindfulness = true,
    MeditationMindfulness = true,
    MindfulnessLast = true,
    MindfulnessMinutes = true,
    LSYoga = true,

    -- Lifestyle moodles, ambitions and progression.
    LSMoodles = true,
    Ambitions = true,
    LSHiddenSkills = true,
    LSCooldowns = true,
    LSDLT = true,
    invData = true,
    KnownArtworkList = true,
    PlayTracker = true,

    -- Learned instrument tracks.
    PianoLearnedTracks = true,
    TrumpetLearnedTracks = true,
    GuitarALearnedTracks = true,
    BanjoLearnedTracks = true,
    KeytarLearnedTracks = true,
    SaxophoneLearnedTracks = true,
    GuitarEBLearnedTracks = true,
    GuitarELearnedTracks = true,
    FluteLearnedTracks = true,
    HarmonicaLearnedTracks = true,
    ViolinLearnedTracks = true,

    -- Wardrobe presets.
    CasualClothes = true,
    FormalClothes = true,
    GymClothes = true,
    SleepClothes = true,
    PartyClothes = true,
    SummerClothes = true,
    WinterClothes = true,
    WorkClothes = true,
    CombatClothes = true,
    ShowerClothes = true,
    ShowerSlots = true,

    -- Persistent preference, comfort and social state.
    LSSocial = true,
    PlayerMusicLike = true,
    PlayerMusicDislike = true,
    PlayerVoice = true,
    HaloCooldownCounter = true,
    CurrentBedQuality = true,
    TDcomplained = true,
    HomeSickCountUp = true,
    HomeSickCountdown = true,
    LSJukeboxCustomPlaylist = true,
    JukeboxVolumeAll = true,
    Jukebox3D = true,

    -- Ambition work counters retained by the original implementation.
    LSCDWPC = true,
    LSBMWPC = true,
    LSTPWPC = true,
}

local function boundedNumber(value)
    if value ~= value then
        return nil
    end
    if value == math.huge or value == -math.huge then
        return nil
    end
    return math.max(Schema.MIN_NUMBER, math.min(Schema.MAX_NUMBER, value))
end

local function boundedString(value, limit)
    if string.len(value) > limit then
        return string.sub(value, 1, limit)
    end
    return value
end

local function sanitizeKey(key)
    local keyType = type(key)
    if keyType == "number" then
        return boundedNumber(key)
    end
    if keyType == "string" then
        return boundedString(key, Schema.MAX_KEY_LENGTH)
    end
    return nil
end

local function sanitizeValue(value, state, depth)
    local valueType = type(value)
    if valueType == "nil" then
        return nil
    end
    if valueType == "boolean" then
        return value
    end
    if valueType == "number" then
        return boundedNumber(value)
    end
    if valueType == "string" then
        return boundedString(value, Schema.MAX_STRING_LENGTH)
    end
    if valueType ~= "table" or depth >= Schema.MAX_DEPTH then
        return nil
    end

    local result = {}
    local localCount = 0
    for key, child in pairs(value) do
        if localCount >= Schema.MAX_TABLE_ENTRIES or state.total >= Schema.MAX_TOTAL_ENTRIES then
            break
        end
        local cleanKey = sanitizeKey(key)
        if cleanKey ~= nil then
            local cleanChild = sanitizeValue(child, state, depth + 1)
            if cleanChild ~= nil then
                result[cleanKey] = cleanChild
                localCount = localCount + 1
                state.total = state.total + 1
            end
        end
    end
    return result
end

function Schema.isPlayerKey(key)
    return type(key) == "string" and Schema.playerKeys[key] == true
end

function Schema.sanitizeValue(value)
    return sanitizeValue(value, { total = 0 }, 0)
end

function Schema.sanitizePlayerData(source)
    local clean = {}
    local state = { total = 0 }
    if type(source) ~= "table" then
        return clean
    end
    for key in pairs(Schema.playerKeys) do
        if source[key] ~= nil and state.total < Schema.MAX_TOTAL_ENTRIES then
            local value = sanitizeValue(source[key], state, 0)
            if value ~= nil then
                clean[key] = value
                state.total = state.total + 1
            end
        end
    end
    return clean
end

function Schema.copyPlayerData(source)
    return Schema.sanitizePlayerData(source)
end

local function valuesEqual(left, right, depth)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    if depth >= Schema.MAX_DEPTH then
        return true
    end
    for key, value in pairs(left) do
        if not valuesEqual(value, right[key], depth + 1) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function tableHasEntries(t)
    if type(t) ~= "table" then
        return false
    end
    for _ in pairs(t) do
        return true
    end
    return false
end

local function arrayLen(t)
    if type(t) ~= "table" then
        return 0
    end
    local n = 0
    local i = 1
    while t[i] ~= nil do
        n = n + 1
        i = i + 1
        if i > Schema.MAX_TABLE_ENTRIES then
            break
        end
    end
    return n
end

function Schema.createDelta(source, baseline)
    local current = Schema.sanitizePlayerData(source)
    local previous = Schema.sanitizePlayerData(baseline)
    local delta = {
        schemaVersion = Schema.schemaVersion,
        set = {},
        remove = {},
    }

    for key, value in pairs(current) do
        if not valuesEqual(value, previous[key], 0) then
            delta.set[key] = value
        end
    end
    for key in pairs(previous) do
        if current[key] == nil then
            delta.remove[#delta.remove + 1] = key
        end
    end
    table.sort(delta.remove)
    return delta
end

function Schema.sanitizeDelta(delta)
    local clean = {
        schemaVersion = Schema.schemaVersion,
        set = {},
        remove = {},
    }
    if type(delta) ~= "table" then
        return clean
    end

    local state = { total = 0 }
    if type(delta.set) == "table" then
        for key, value in pairs(delta.set) do
            if Schema.isPlayerKey(key) and state.total < Schema.MAX_TOTAL_ENTRIES then
                local cleanValue = sanitizeValue(value, state, 0)
                if cleanValue ~= nil then
                    clean.set[key] = cleanValue
                    state.total = state.total + 1
                end
            end
        end
    end

    local seen = {}
    if type(delta.remove) == "table" then
        local removeLen = arrayLen(delta.remove)
        local i
        for i = 1, math.min(removeLen, Schema.MAX_TABLE_ENTRIES) do
            local key = delta.remove[i]
            if Schema.isPlayerKey(key) and not seen[key] then
                clean.remove[#clean.remove + 1] = key
                seen[key] = true
            end
        end
    end
    table.sort(clean.remove)
    return clean
end

-- Kahlua-safe: never use # / next on unsanitized values (Java lists throw "call nil").
function Schema.isDeltaEmpty(delta)
    if type(delta) ~= "table" then
        return true
    end
    if tableHasEntries(delta.set) then
        return false
    end
    return arrayLen(delta.remove) == 0
end

function Schema.applyDelta(target, delta)
    if type(target) ~= "table" then
        return false
    end
    local clean = Schema.sanitizeDelta(delta)
    local changed = false
    for key, value in pairs(clean.set) do
        if not valuesEqual(target[key], value, 0) then
            target[key] = value
            changed = true
        end
    end
    for i = 1, #clean.remove do
        local key = clean.remove[i]
        if target[key] ~= nil then
            target[key] = nil
            changed = true
        end
    end
    return changed, clean
end

function Schema.applyOwnedData(target, source)
    if type(target) ~= "table" then
        return false
    end
    local clean = Schema.sanitizePlayerData(source)
    local changed = false
    for key in pairs(Schema.playerKeys) do
        if clean[key] ~= nil then
            if not valuesEqual(target[key], clean[key], 0) then
                target[key] = clean[key]
                changed = true
            end
        end
    end
    return changed
end

return Schema
