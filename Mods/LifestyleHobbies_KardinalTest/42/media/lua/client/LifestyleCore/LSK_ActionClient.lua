require "TimedActions/ISBaseTimedAction"
require "LifestyleCore/LSK_Features"

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.ActionClient = LifestyleSecure.ActionClient or {}

local ActionClient = LifestyleSecure.ActionClient
local installed = false
local originalSendClientCommand = nil

local ACTION_PREFIXES = {
    "LS",
    "PlayInstrument",
    "PlayDJ",
    "PlayerIsDancing",
    "CleanRoom",
    "Jukebox",
    "DiscoBall",
    "ToneDeaf",
    "Booing",
    "Praise",
    "Shoo",
}

local function ensureSystemsClient()
    if not LifestyleSecure.ClientSystems then
        pcall(require, "LifestyleCore/LSK_SystemsClient")
    end
end

local function actionName(action)
    if not action then
        return nil
    end
    local name = action.Type or action.type
    if type(name) ~= "string" then
        local mt = getmetatable(action)
        name = mt and mt.Type or nil
    end
    return type(name) == "string" and name or nil
end

local function isLifestyleAction(action)
    local name = actionName(action)
    if not name then
        return false
    end
    for i = 1, #ACTION_PREFIXES do
        if string.sub(name, 1, string.len(ACTION_PREFIXES[i])) == ACTION_PREFIXES[i] then
            return true
        end
    end
    return false
end

local function isPlayerArg(obj)
    if obj == nil then
        return false
    end
    if type(obj) == "userdata" then
        return true
    end
    if instanceof and instanceof(obj, "IsoPlayer") then
        return true
    end
    return false
end

local function generateNonce(character, name)
    local playerId = character and character.getOnlineID and character:getOnlineID() or 0
    local stamp = getTimestampMs and getTimestampMs() or (os.time() * 1000)
    stamp = math.floor(tonumber(stamp) or 0)
    local randomPart = ZombRand and ZombRand(1000000000) or math.random(1, 999999999)
    local safeName = tostring(name or "Action"):gsub("[^%w_%-]", "")
    if safeName == "" then
        safeName = "Action"
    end
    return tostring(playerId) .. "-" .. tostring(stamp) .. "-" .. tostring(randomPart) .. "-" .. safeName
end

local function currentSession(character)
    local data = character and character.getModData and character:getModData()
    return data and data.LifestyleSecureActionClient or nil
end

local function clearSession(character, notify)
    local data = character and character.getModData and character:getModData()
    local session = data and data.LifestyleSecureActionClient
    if not session then
        return
    end
    data.LifestyleSecureActionClient = nil
    if notify and originalSendClientCommand and character then
        originalSendClientCommand(character, "LSK", "LSK_EndAction", {
            session.action,
            session.nonce,
        })
    end
end

local function sendBeginAction(character, name, nonce, durationMilliseconds)
    local beginArgs = {
        name,
        nonce,
        durationMilliseconds,
    }
    if originalSendClientCommand then
        originalSendClientCommand(character, "LSK", "LSK_BeginAction", beginArgs)
    else
        sendClientCommand(character, "LSK", "LSK_BeginAction", beginArgs)
    end
end

local function beginSession(action, force)
    -- Listen-server host is both client and server; still must register action proof.
    if not isClient() or not isLifestyleAction(action) then
        return false
    end
    if not LifestyleSecure.Features.IsModActive() then
        return false
    end
    local character = action.character
    if not character then
        return false
    end
    local name = actionName(action)
    if not name then
        return false
    end
    local now = getTimestampMs and getTimestampMs() or 0
    local existing = currentSession(character)
    -- Reuse active proof for the same action (begin+start double-call, NetTimedAction).
    if not force and existing and existing.action == name
        and (not existing.expiresAt or existing.expiresAt > now) then
        action._lskSessionStarted = true
        return true
    end
    clearSession(character, true)
    -- Yoga uses maxTime=-1 (open-ended). duration*(-1) collapsed to the 5s floor and
    -- AddXP arrived after action_proof expiry (server: action_proof_invalid).
    local duration = tonumber(action.maxTime) or 300
    local durationMilliseconds
    if duration <= 0 then
        durationMilliseconds = 1800000
    else
        durationMilliseconds = math.min(3600000, math.max(5000, math.floor(duration * 50)))
    end
    local nonce = generateNonce(character, name)
    character:getModData().LifestyleSecureActionClient = {
        action = name,
        nonce = nonce,
        expiresAt = now + durationMilliseconds + 30000,
    }
    action._lskSessionStarted = true
    sendBeginAction(character, name, nonce, durationMilliseconds)
    return true
end

-- If AddXP fires without a live proof (B42 skip begin / race), open a short emergency session.
local function ensureProofForCommand(character, command, payload)
    if not character or not isClient() then
        return currentSession(character)
    end
    local session = currentSession(character)
    if session then
        return session
    end
    if command ~= "AddXP" and command ~= "AddXPBatch" then
        return nil
    end
    if not LifestyleSecure.Features.IsModActive() then
        return nil
    end
    -- Pick a plausible Lifestyle action name from the perk so server allow-list accepts it.
    local perk = type(payload) == "table" and payload[1] or nil
    local name = "CleanRoomAction"
    if perk == "Meditation" then
        name = "LSMeditateAction"
    elseif perk == "Fitness" or perk == "Nimble" then
        name = "LSYogaAction"
    elseif perk == "Music" then
        name = "PlayInstrumentAction"
    elseif perk == "Dancing" then
        name = "PlayerIsDancing"
    elseif perk == "Art" then
        name = "LSSculptingAction"
    elseif perk == "Cleaning" then
        name = "LSCleanObject"
    end
    local durationMilliseconds = 120000
    local nonce = generateNonce(character, name)
    local now = getTimestampMs and getTimestampMs() or 0
    character:getModData().LifestyleSecureActionClient = {
        action = name,
        nonce = nonce,
        expiresAt = now + durationMilliseconds + 30000,
    }
    sendBeginAction(character, name, nonce, durationMilliseconds)
    return currentSession(character)
end

local function wrapSendClientCommand()
    if originalSendClientCommand or not sendClientCommand then
        return
    end
    originalSendClientCommand = sendClientCommand
    -- B42 Java overloads need an args table. Do not forward (player, module, command)
    -- without a 4th arg - AVCS and others call 3-arg form and MultiLuaJavaInvoker fails.
    sendClientCommand = function(...)
        local a1, a2, a3, a4 = ...
        local character
        local module
        local command
        local payload
        -- B42: IsoPlayer is often userdata; also accept instanceof for safety.
        local withPlayer = isPlayerArg(a1) and type(a2) == "string"

        if withPlayer then
            character = a1
            module = a2
            command = a3
            payload = a4
        else
            character = getPlayer and getPlayer() or nil
            module = a1
            command = a2
            payload = a3
        end

        if (module == "LSK" or module == "LSKPersistence")
            and not LifestyleSecure.Features.IsModActive()
            and command ~= "RequestSnapshot"
            and command ~= "MigrationReport" then
            return
        end

        if module == "LSK"
            and command ~= "LSK_BeginAction"
            and command ~= "LSK_EndAction" then
            local session = ensureProofForCommand(character, command, payload)
            if session then
                if type(payload) ~= "table" then
                    if payload == nil then
                        payload = {}
                    else
                        payload = { payload }
                    end
                end
                payload.__lsk = {
                    action = session.action,
                    nonce = session.nonce,
                }
            end
        end

        if type(payload) ~= "table" then
            payload = {}
        end

        if withPlayer then
            return originalSendClientCommand(character, module, command, payload)
        end
        return originalSendClientCommand(module, command, payload)
    end
end

local function install()
    if installed then
        return
    end
    installed = true
    ensureSystemsClient()
    wrapSendClientCommand()

    local originalIsValid = ISBaseTimedAction.isValid
    function ISBaseTimedAction:isValid()
        if isLifestyleAction(self) and not LifestyleSecure.Features.IsModActive() then
            return false
        end
        return originalIsValid(self)
    end

    if ISBaseTimedAction.isValidStart then
        local originalIsValidStart = ISBaseTimedAction.isValidStart
        function ISBaseTimedAction:isValidStart()
            if isLifestyleAction(self) and not LifestyleSecure.Features.IsModActive() then
                return false
            end
            return originalIsValidStart(self)
        end
    end

    local originalBegin = ISBaseTimedAction.begin
    function ISBaseTimedAction:begin()
        if isLifestyleAction(self) and not LifestyleSecure.Features.IsModActive() then
            return
        end
        beginSession(self, false)
        return originalBegin(self)
    end

    -- B42 NetTimedAction: some paths hit start() without a fresh Lua begin().
    local originalStart = ISBaseTimedAction.start
    function ISBaseTimedAction:start()
        if isLifestyleAction(self) and LifestyleSecure.Features.IsModActive() then
            if not self._lskSessionStarted then
                beginSession(self, false)
            end
        end
        return originalStart(self)
    end

    local originalPerform = ISBaseTimedAction.perform
    function ISBaseTimedAction:perform()
        local character = self.character
        -- Chain after any earlier perform patch; B42 NetTimedAction expects a boolean.
        local r1, r2, r3, r4 = originalPerform(self)
        clearSession(character, true)
        if self then
            self._lskSessionStarted = nil
        end
        if r1 ~= nil then
            return r1, r2, r3, r4
        end
        return true
    end

    local originalStop = ISBaseTimedAction.stop
    function ISBaseTimedAction:stop()
        local character = self.character
        local result = originalStop(self)
        clearSession(character, true)
        if self then
            self._lskSessionStarted = nil
        end
        return result
    end

    local originalForceCancel = ISBaseTimedAction.forceCancel
    function ISBaseTimedAction:forceCancel()
        clearSession(self.character, true)
        if self then
            self._lskSessionStarted = nil
        end
        return originalForceCancel(self)
    end
end

local function onServerCommand(module, command, args)
    if module ~= "LSK" or command ~= "LSK_ActionState" or type(args) ~= "table" then
        return
    end
    if args.accepted == false then
        local player = getPlayer and getPlayer() or nil
        local session = currentSession(player)
        if session and session.nonce == args.nonce then
            clearSession(player, false)
            if player then
                -- allow start() to open a new proof on the next tick
                local queue = ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue
                    and ISTimedActionQueue.getTimedActionQueue(player)
                local current = queue and queue.current
                if current then
                    current._lskSessionStarted = nil
                end
            end
        end
    end
end

Events.OnGameBoot.Remove(install)
Events.OnGameBoot.Add(install)
Events.OnServerCommand.Add(onServerCommand)

return ActionClient
