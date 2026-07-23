require "LifestyleCore/LSK_ActionClient"

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.ClientSystems = LifestyleSecure.ClientSystems or {}

local ClientSystems = LifestyleSecure.ClientSystems

local KNOWN_INVENTIONS = {
    Hygienator = true,
    FoodSynthesizer = true,
    Harvester = true,
    PowerAxe = true,
    NeuralHat = true,
}

local INSTRUMENT_IDS = {
    Piano = "Piano",
    Trumpet = "Trumpet",
    GuitarAcoustic = "GuitarA",
    Banjo = "Banjo",
    Keytar = "Keytar",
    Saxophone = "Saxophone",
    GuitarElectricBass = "GuitarEB",
    GuitarElectric = "GuitarE",
    Flute = "Flute",
    Harmonica = "Harmonica",
    Violin = "Violin",
    trumpet = "Trumpet",
    guitarA = "GuitarA",
    banjo = "Banjo",
    keytar = "Keytar",
    sax = "Saxophone",
    guitarEB = "GuitarEB",
    guitarE = "GuitarE",
    flute = "Flute",
    piano = "Piano",
    harmonica = "Harmonica",
    violin = "Violin",
}

local WELLNESS_LIMITS = {
    maxHeal = 10,
    maxStiffnessReduction = 25,
    maxXp = 90,
    maxFitnessXp = 250,
    maxNimbleXp = 120,
}

local function clampNumber(value, minimum, maximum)
    value = tonumber(value)
    if not value then
        return 0
    end
    return math.max(minimum, math.min(maximum, value))
end

local function playerModData(player)
    if not player or not player.getModData then
        return nil
    end
    return player:getModData()
end

local function sendCommand(player, command, payload)
    if not isClient() or not sendClientCommand or not player then
        return false
    end
    sendClientCommand(player, "LSK", command, payload or {})
    return true
end

function ClientSystems.isMpClient()
    return isClient() and not isServer()
end

function ClientSystems.shouldApplyLocalWellnessBodyRewards()
    return not ClientSystems.isMpClient()
end

function ClientSystems.mapInstrumentId(instrumentType)
    if type(instrumentType) ~= "string" then
        return nil
    end
    return INSTRUMENT_IDS[instrumentType] or instrumentType
end

function ClientSystems.mapComfortPresetName(optionName)
    if type(optionName) ~= "string" or optionName == "" then
        return nil
    end
    if string.sub(optionName, -7) == "Clothes" then
        return optionName
    end
    return optionName .. "Clothes"
end

local function storeSession(player, bucket, session)
    local data = playerModData(player)
    if not data then
        return
    end
    data.LSK_SystemSessions = data.LSK_SystemSessions or {}
    data.LSK_SystemSessions[bucket] = session
end

local function getSession(player, bucket)
    local data = playerModData(player)
    local sessions = data and data.LSK_SystemSessions
    return sessions and sessions[bucket] or nil
end

local function clearSession(player, bucket)
    local data = playerModData(player)
    if not data or not data.LSK_SystemSessions then
        return
    end
    data.LSK_SystemSessions[bucket] = nil
end

function ClientSystems.beginWellness(player, actionName, durationMs)
    durationMs = clampNumber(durationMs, 5000, 1800000)
    storeSession(player, "wellness", {
        action = actionName,
        nonce = nil,
        durationMs = durationMs,
        pendingComplete = nil,
    })
    return sendCommand(player, "LSK_WellnessBegin", { actionName, durationMs })
end

function ClientSystems.completeWellness(player, nonce, requested)
    requested = type(requested) == "table" and requested or {}
    local maxFit = WELLNESS_LIMITS.maxFitnessXp or 250
    local maxNim = WELLNESS_LIMITS.maxNimbleXp or 120
    local payload = {
        healing = clampNumber(requested.healing, 0, WELLNESS_LIMITS.maxHeal),
        stiffness = clampNumber(requested.stiffness, 0, WELLNESS_LIMITS.maxStiffnessReduction),
        xp = clampNumber(requested.xp, 0, WELLNESS_LIMITS.maxXp),
        fitnessXp = clampNumber(requested.fitnessXp, 0, maxFit),
        nimbleXp = clampNumber(requested.nimbleXp, 0, maxNim),
    }
    -- Callers pass nil and expect us to use the Begin response nonce.
    -- If Begin already arrived, send Complete now; otherwise queue until ActionState.
    if not nonce then
        local session = getSession(player, "wellness")
        if session and type(session.nonce) == "string" and session.nonce ~= "" then
            nonce = session.nonce
        elseif session then
            session.pendingComplete = payload
            return false
        else
            return false
        end
    end
    clearSession(player, "wellness")
    return sendCommand(player, "LSK_WellnessComplete", { nonce, payload })
end

function ClientSystems.learnTrack(player, instrument, trackId)
    local instrumentId = ClientSystems.mapInstrumentId(instrument)
    if not instrumentId or type(trackId) ~= "string" or trackId == "" then
        return false
    end
    return sendCommand(player, "LSK_LearnTrack", { instrumentId, trackId })
end

function ClientSystems.ambitionProgress(player, ambitionId, goalIndex, delta)
    goalIndex = math.floor(clampNumber(goalIndex, 1, 6))
    delta = clampNumber(delta, 0, 100000000)
    if not ambitionId or delta <= 0 then
        return false
    end
    return sendCommand(player, "LSK_AmbitionProgress", { ambitionId, goalIndex, delta })
end

function ClientSystems.saveComfortPreset(player, presetName, itemIds)
    presetName = ClientSystems.mapComfortPresetName(presetName)
    if not presetName or type(itemIds) ~= "table" then
        return false
    end
    local cleanIds = {}
    for i = 1, math.min(#itemIds, 32) do
        local itemId = itemIds[i]
        if type(itemId) == "string" and itemId ~= "" then
            cleanIds[#cleanIds + 1] = itemId
        end
    end
    return sendCommand(player, "LSK_ComfortSavePreset", { presetName, cleanIds })
end

function ClientSystems.beginInvention(player, mode, inventionId, durationMs, contract)
    if mode ~= "Research" and mode ~= "Production" then
        return false
    end
    if not KNOWN_INVENTIONS[inventionId] then
        return false
    end
    durationMs = clampNumber(durationMs, 5000, 3600000)
    contract = type(contract) == "table" and contract or {}
    storeSession(player, "invention", {
        mode = mode,
        inventionId = inventionId,
        nonce = nil,
        pendingComplete = nil,
    })
    return sendCommand(player, "LSK_InventionBegin", {
        mode,
        inventionId,
        durationMs,
        contract,
    })
end

function ClientSystems.completeInvention(player, nonce)
    if not nonce then
        local session = getSession(player, "invention")
        if session and type(session.nonce) == "string" and session.nonce ~= "" then
            nonce = session.nonce
        elseif session then
            session.pendingComplete = true
            return false
        else
            return false
        end
    end
    clearSession(player, "invention")
    return sendCommand(player, "LSK_InventionComplete", { nonce })
end

function ClientSystems.claimHygieneFixture(player, x, y, z, sprite, fixtureType)
    if not player then
        return false
    end
    return sendCommand(player, "LSK_HygieneClaimFixture", {
        x,
        y,
        z,
        tostring(sprite or ""),
        fixtureType or "Toilet",
    })
end

local function onServerCommand(module, command, args)
    if module ~= "LSK" or type(args) ~= "table" then
        return
    end

    local player = getPlayer and getPlayer() or nil
    if not player then
        return
    end

    if command == "LSK_ActionState" then
        local phase = args.phase or args.event or args[1] or args[0]
        local actionName = args.action or args[2] or args[1]
        local nonce = args.nonce or args[3] or args[2]
        -- Array form: {"begin", action, nonce} (1-based) or [0]="begin"...
        if phase ~= "begin" and args[1] == "begin" then
            phase = "begin"
            actionName = args[2]
            nonce = args[3]
        elseif phase ~= "begin" and args[0] == "begin" then
            phase = "begin"
            actionName = args[1]
            nonce = args[2]
        end
        if phase ~= "begin" then
            return
        end
        if type(nonce) ~= "string" then
            return
        end
        if actionName == "Yoga" or actionName == "Meditation" then
            local session = getSession(player, "wellness") or {}
            session.action = actionName
            session.nonce = nonce
            storeSession(player, "wellness", session)
            if session.pendingComplete then
                local pending = session.pendingComplete
                session.pendingComplete = nil
                ClientSystems.completeWellness(player, nonce, pending)
            end
        elseif type(actionName) == "string" and string.sub(actionName, 1, 4) == "LSIW" then
            local session = getSession(player, "invention") or {}
            session.nonce = nonce
            storeSession(player, "invention", session)
            if session.pendingComplete then
                session.pendingComplete = nil
                ClientSystems.completeInvention(player, nonce)
            end
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)

return ClientSystems
