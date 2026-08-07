--//////////////////////////////////////////////////--
--    Reactive Sound Events - Knox Relay Radio
--    Radio station broadcasting scene intel
--//////////////////////////////////////////////////--

if isClient() and not isServer() then return end

local Constants        = require "ReactiveSE/ReactiveSE_Constants"
local Utils            = require "ReactiveSE/ReactiveSE_Utils"
local Config           = require "ReactiveSE/ReactiveSE_Config"
local SceneManager     = require "ReactiveSE/ReactiveSE_SceneManager"
local RadioMessages    = require "ReactiveSE/ReactiveSE_RadioMessages"

local ReactiveSE_Radio = {}

--//////////////////////////////////////////////////--
--          Channel Registration                   --
--//////////////////////////////////////////////////--

if DynamicRadio then
    DynamicRadio.channels = DynamicRadio.channels or {}

    local found = false
    for i = 1, #DynamicRadio.channels do
        local ch = DynamicRadio.channels[i]
        if ch and ch.uuid == Constants.Radio.UUID then
            found = true
            break
        end
    end

    if not found then
        local radio = Constants.Radio
        table.insert(DynamicRadio.channels, {
            name = radio.NAME,
            freq = radio.NEW_FREQ,
            category = radio.CATEGORY,
            uuid = radio.UUID,
            register = true,
            airCounterMultiplier = 1.5,
        })
    end
end

--//////////////////////////////////////////////////--
--          Channel Access                          --
--//////////////////////////////////////////////////--

local function getRadioChannel()
    if DynamicRadio and DynamicRadio.cache then
        return DynamicRadio.cache[Constants.Radio.UUID]
    end
    return nil
end

local function createRadioBroadcast(broadcastData)
    if not RadioBroadCast or not RadioLine then
        Utils.LogWarning("[Radio] RadioBroadCast/RadioLine API not available")
        return nil
    end

    local rb = RadioBroadCast.new(Constants.Radio.UUID, -1, -1)
    for i = 1, #broadcastData do
        local lineData = broadcastData[i]
        local r = lineData.r or 0.75
        local g = lineData.g or 0.75
        local b = lineData.b or 0.75
        local fx = lineData.fx

        if fx and fx ~= "" then
            rb:AddRadioLine(RadioLine.new(lineData.text, r, g, b, fx))
        else
            rb:AddRadioLine(RadioLine.new(lineData.text, r, g, b))
        end
    end

    return rb
end

--//////////////////////////////////////////////////--
--          Host Rotation Logic                    --
--//////////////////////////////////////////////////--

local function getMorningShowHost(day)
    local timeline = Constants.RadioTimeline
    local hosts = Constants.RadioHosts

    -- Phase 1: Jenna hosts (Days 1-30)
    if day <= timeline.JENNA_LAST_DAY then
        local isSpecial = (day == timeline.JENNA_LAST_DAY)
        return hosts.JENNA, isSpecial
    end

    -- Phase 2: Ray hosts on specific days (Days 31-90)
    if day <= timeline.RAY_LAST_DAY then
        local isSpecial = (day == timeline.RAY_LAST_DAY)
        return hosts.RAY, isSpecial
    end

    -- Phase 3: Marcus hosts final shows (Days 91-92)
    for i = 1, #timeline.MARCUS_FINAL_DAYS do
        if timeline.MARCUS_FINAL_DAYS[i] == day then
            return hosts.MARCUS, false
        end
    end

    return nil, false
end

---Determines which host does intel and what type of broadcast
---@param day number Current game day
---@param hour number Current hour (13 or 19)
---@return string host, string broadcastType ("normal", "special_day30", "special_day90")
local function getIntelBroadcastInfo(day, hour)
    local timeline = Constants.RadioTimeline
    local hosts = Constants.RadioHosts

    -- Day 30: Jenna leaving - Marcus at 13, Ray at 19
    if day == timeline.JENNA_LAST_DAY then
        if hour == 13 then
            return hosts.MARCUS, "special_day30_marcus"
        else
            return hosts.RAY, "special_day30_ray"
        end
    end

    -- Day 90: Ray's death - Marcus at both 13 and 19
    if day == timeline.RAY_LAST_DAY then
        return hosts.MARCUS, "special_day90"
    end

    -- Normal intel broadcast
    return hosts.MARCUS, "normal"
end

--//////////////////////////////////////////////////--
--          Broadcast Building                     --
--//////////////////////////////////////////////////--

local function broadcastMorningShow(host, isSpecial, day)
    if not RadioMessages then
        Utils.LogWarning("[Radio] RadioMessages not loaded")
        return
    end

    local broadcast = RadioMessages.BuildMorningShow(host, isSpecial, day)
    if not broadcast then
        Utils.LogWarning("[Radio] Failed to build morning show broadcast")
        return
    end

    local radioChannel = getRadioChannel()
    if not radioChannel then
        Utils.LogWarning("[Radio] Could not get radio channel")
        return
    end

    local radioBroadcast = createRadioBroadcast(broadcast)
    if radioBroadcast then
        radioChannel:setAiringBroadcast(radioBroadcast)
        Utils.LogInfo("[Radio] Morning show aired - Host: " .. host .. ", Day: " .. day)
    end
end

---Gets intel from radio queue (Dedicated Server only)
---@return table|nil
local function getRadioIntel()
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData.radioIntelQueue or #modData.radioIntelQueue == 0 then
        return nil
    end
    return table.remove(modData.radioIntelQueue, 1)
end

local function broadcastIntelReport(day, hour)
    if not RadioMessages then
        Utils.LogWarning("[Radio] RadioMessages not loaded")
        return
    end

    local host, broadcastType = getIntelBroadcastInfo(day, hour)
    local broadcast
    local intel = nil

    -- Detect environment
    local isSP = ReactiveSE_State.isSingleplayer
    local isHost = isServer() and isClient()

    if broadcastType == "special_day30_marcus" then
        -- Day 30, 13:00 - Marcus reacting to Jenna leaving
        broadcast = RadioMessages.BuildJennaDepartureIntel("marcus")
    elseif broadcastType == "special_day30_ray" then
        -- Day 30, 19:00 - Ray reacting to Jenna leaving
        broadcast = RadioMessages.BuildJennaDepartureIntel("ray")
    elseif broadcastType == "special_day90" then
        -- Day 90 - Marcus announcing Ray's death
        broadcast = RadioMessages.BuildRayDeathIntel()
    else
        if isSP or isHost then
            intel = SceneManager.GetUnspawnedScene()
        else
            intel = getRadioIntel()
        end
        broadcast = RadioMessages.BuildIntelReport(host, intel)
    end

    if not broadcast then
        Utils.LogWarning("[Radio] Failed to build intel broadcast")
        return
    end

    local radioChannel = getRadioChannel()
    if not radioChannel then
        Utils.LogWarning("[Radio] Could not get radio channel")
        return
    end

    local radioBroadcast = createRadioBroadcast(broadcast)
    if radioBroadcast then
        radioChannel:setAiringBroadcast(radioBroadcast)

        if intel then
            -- Mark as broadcasted in SP/Host (SceneManager tracks this)
            if isSP or isHost then
                SceneManager.MarkAsBroadcasted(intel.id)
            end

            -- Deliver intel to clients
            if isSP then
                -- SP: local event only
                triggerEvent("OnKnoxRelayMarker", intel.x, intel.y, intel.type, intel.id)
            else
                -- Host or Dedicated: send to all clients
                sendServerCommand(Constants.MOD_ID, Constants.NetworkCommands.RADIO_INTEL, {
                    x = intel.x,
                    y = intel.y,
                    sceneType = intel.type,
                    sceneID = intel.id
                })
            end
        end

        Utils.LogInfo("[Radio] Intel broadcast aired - Host: " .. host .. ", Type: " .. broadcastType)
    end
end

--//////////////////////////////////////////////////--
--          Scheduler                              --
--//////////////////////////////////////////////////--

local function onEveryHour()
    local cfg = Config.Get()

    if not cfg.radio or not cfg.radio.enabled then
        return
    end

    local gameTime = getGameTime()
    local hour = gameTime:getHour()
    local day = gameTime:getNightsSurvived()

    -- Check if this is a broadcast hour (7, 13, or 19)
    local broadcastHours = Constants.Radio.BROADCAST_HOURS
    local isBroadcastHour = false
    for i = 1, #broadcastHours do
        if broadcastHours[i] == hour then
            isBroadcastHour = true
            break
        end
    end

    if not isBroadcastHour then
        return
    end

    -- Check if we already broadcast this hour today
    local modData = ReactiveSE_Initialize.GetModData()
    if modData.radioLastBroadcastDay == day and modData.radioLastBroadcastHour == hour then
        return
    end

    modData.radioLastBroadcastDay = day
    modData.radioLastBroadcastHour = hour

    -- Morning show at 7 AM
    if hour == broadcastHours[1] then
        if modData.radioMorningShowPlayedToday then
            return
        end

        local host, isSpecial = getMorningShowHost(day)
        if host then
            modData.radioMorningShowPlayedToday = true
            broadcastMorningShow(host, isSpecial, day)
        end
    else
        -- Intel broadcast (1 PM or 7 PM)
        broadcastIntelReport(day, hour)
    end
end

local function onEveryDay()
    local modData = ReactiveSE_Initialize.GetModData()
    modData.radioMorningShowPlayedToday = false
end

--//////////////////////////////////////////////////--
--          Initialization                         --
--//////////////////////////////////////////////////--

function ReactiveSE_Radio.Initialize()
    local cfg = Config.Get()

    if not cfg.radio or not cfg.radio.enabled then
        Utils.LogInfo("[Radio] Knox Relay disabled in sandbox options")
        return
    end

    Events.EveryHours.Add(onEveryHour)
    Events.EveryDays.Add(onEveryDay)

    Utils.LogInfo("[Radio] Knox Relay initialized successfully")
end

return ReactiveSE_Radio
