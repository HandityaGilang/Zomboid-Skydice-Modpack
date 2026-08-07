--//////////////////////////////////////////////////--
--    Reactive Sound Events - Radio Messages
--    Message pools and broadcast builders
--//////////////////////////////////////////////////--

local Constants                = require "ReactiveSE/ReactiveSE_Constants"
local Config                   = require "ReactiveSE/ReactiveSE_Config"
local RadioFallback            = require "ReactiveSE/ReactiveSE_RadioFallback"

local ReactiveSE_RadioMessages = {}

--//////////////////////////////////////////////////--
--          Configuration                          --
--//////////////////////////////////////////////////--

local Colors                   = {
    MARCUS = { r = 0.39, g = 0.58, b = 0.93 },  -- Cornflower blue
    JENNA = { r = 1.0, g = 0.71, b = 0.76 },    -- Light pink
    RAY = { r = 0.82, g = 0.71, b = 0.55 },     -- Tan
    SCENE = { r = 1.0, g = 0.78, b = 0.39 },    -- Gold
    WARNING = { r = 1.0, g = 0.39, b = 0.39 },  -- Red
    DEFAULT = { r = 0.75, g = 0.75, b = 0.75 }, -- Light gray
}

--//////////////////////////////////////////////////--
--          Internal Helpers                       --
--//////////////////////////////////////////////////--

---Picks a random index from 1 to count
---@param count number
---@return number
local function pickRandomIndex(count)
    if count <= 0 then return 1 end
    return ZombRand(count) + 1
end

---Gets host color
---@param host string
---@return table
local function getHostColor(host)
    local hosts = Constants.RadioHosts
    if host == hosts.MARCUS then
        return Colors.MARCUS
    elseif host == hosts.JENNA then
        return Colors.JENNA
    elseif host == hosts.RAY then
        return Colors.RAY
    end
    return Colors.DEFAULT
end

---Creates a broadcast line entry
---@param text string
---@param color table|nil
---@param fx string|nil XP effect string (e.g., "ELC+5" for Electrical XP)
---@return table
local function line(text, color, fx)
    color = color or Colors.DEFAULT
    return { text = text, r = color.r, g = color.g, b = color.b, fx = fx or "" }
end

---Formats day number with leading zero for keys
---@param day number
---@return string
local function formatDay(day)
    if day < 10 then
        return "0" .. tostring(day)
    end
    return tostring(day)
end

---Gets the XP effect string for a skill tip based on host and day
---@param host string
---@param day number
---@return string XP effect string (e.g., "ELC+5")
local function getSkillXPEffect(host, day)
    local hosts = Constants.RadioHosts

    if host == hosts.JENNA then
        -- Jenna: odd days = Electrical, even days = Carpentry (days 1-15) or Mechanics (days 16+)
        if day % 2 == 1 then
            return "ELC+1"
        elseif day <= 15 then
            return "CRP+1"
        else
            return "MEC+1"
        end
    elseif host == hosts.RAY then
        if day > 31 and day <= 38 then
            return "CRP+1"
        elseif day > 38 and day <= 45 then
            return "FRM+1"
        elseif day > 45 and day <= 52 then
            return "DOC+1"
        elseif day > 52 and day <= 59 then
            return "FIS+1"
        elseif day > 59 and day <= 66 then
            return "FOR+1"
        elseif day > 66 and day <= 73 then
            return "TRA+1"
        elseif day > 73 and day <= 80 then
            return "MEC+1"
        elseif day > 80 and day <= 87 then
            return "TAI+1"
        end
    end

    return "" -- Marcus doesn't give skill XP
end

--//////////////////////////////////////////////////--
--          Morning Show Segment Getters           --
--//////////////////////////////////////////////////--

---Gets a random reusable welcome for the host
---@param host string
---@return string
local function getMorningWelcome(host)
    local hostKey = "Marcus"
    if host == Constants.RadioHosts.JENNA then
        hostKey = "Jenna"
    elseif host == Constants.RadioHosts.RAY then
        hostKey = "Ray"
    end
    local idx = pickRandomIndex(2)
    return RadioFallback.ResolveText("IGUI_KnoxRelay_MorningShow_" .. hostKey .. "_Welcome_0" .. idx)
end

---Gets a random reusable wrap-up for the host
---@param host string
---@return string
local function getMorningWrapup(host)
    local hostKey = "Marcus"
    if host == Constants.RadioHosts.JENNA then
        hostKey = "Jenna"
    elseif host == Constants.RadioHosts.RAY then
        hostKey = "Ray"
    end
    local idx = pickRandomIndex(2)
    return RadioFallback.ResolveText("IGUI_KnoxRelay_MorningShow_" .. hostKey .. "_Wrapup_0" .. idx)
end

---Gets a random reusable sign-off for the host
---@param host string
---@return string
local function getMorningSignoff(host)
    local hostKey = "Marcus"
    if host == Constants.RadioHosts.JENNA then
        hostKey = "Jenna"
    elseif host == Constants.RadioHosts.RAY then
        hostKey = "Ray"
    end
    local idx = pickRandomIndex(2)
    return RadioFallback.ResolveText("IGUI_KnoxRelay_MorningShow_" .. hostKey .. "_Signoff_0" .. idx)
end

---Gets day-specific content for segments 2-6
---@param host string
---@param day number
---@return string, string, string, string, string
local function getMorningDayContent(host, day)
    local hostKey = "Marcus"
    if host == Constants.RadioHosts.JENNA then
        hostKey = "Jenna"
    elseif host == Constants.RadioHosts.RAY then
        hostKey = "Ray"
    end

    local dayStr = formatDay(day)
    local prefix = "IGUI_KnoxRelay_MorningShow_" .. hostKey .. "_Day" .. dayStr .. "_S"

    local s2 = RadioFallback.ResolveText(prefix .. "2")
    local s3 = RadioFallback.ResolveText(prefix .. "3")
    local s4 = RadioFallback.ResolveText(prefix .. "4")
    local s5 = RadioFallback.ResolveText(prefix .. "5")
    local s6 = RadioFallback.ResolveText(prefix .. "6")

    return s2, s3, s4, s5, s6
end

--//////////////////////////////////////////////////--
--          Intel Report Segment Getters           --
--//////////////////////////////////////////////////--

---Gets the host's phase key based on the day (for intel reports)
---@param host string
---@param day number
---@return string phaseKey
local function getHostPhaseKey(host, day)
    local timeline = Constants.RadioTimeline
    local hosts = Constants.RadioHosts

    if host == hosts.MARCUS then
        if day <= timeline.JENNA_LAST_DAY then
            return "MarcusBeforeJenna"
        elseif day <= timeline.RAY_LAST_DAY then
            return "MarcusAfterJenna"
        else
            return "MarcusAfterRay"
        end
    elseif host == hosts.JENNA then
        return "Jenna"
    elseif host == hosts.RAY then
        if day <= timeline.JENNA_LAST_DAY then
            return "RayBeforeJenna"
        else
            return "RayAfterJenna"
        end
    end
    return "MarcusBeforeJenna"
end

---Gets welcome message for intel broadcasts
---@param host string
---@param day number
---@return string
local function getIntelWelcome(host, day)
    local timeline = Constants.RadioTimeline
    local hosts = Constants.RadioHosts
    local idx = pickRandomIndex(5)

    if host == hosts.MARCUS then
        if day > timeline.RAY_LAST_DAY then
            return RadioFallback.ResolveText("IGUI_KnoxRelay_Welcome_MarcusAfterRay_0" .. idx)
        else
            return RadioFallback.ResolveText("IGUI_KnoxRelay_Welcome_Marcus_0" .. idx)
        end
    elseif host == hosts.JENNA then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_Welcome_Jenna_0" .. idx)
    elseif host == hosts.RAY then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_Welcome_Ray_0" .. idx)
    end
    return ""
end

---Gets sign-off message for intel broadcasts
---@param host string
---@return string
local function getIntelSignOff(host)
    local hosts = Constants.RadioHosts
    local idx = pickRandomIndex(5)

    if host == hosts.MARCUS then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_SignOff_Marcus_0" .. idx)
    elseif host == hosts.JENNA then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_SignOff_Jenna_0" .. idx)
    elseif host == hosts.RAY then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_SignOff_Ray_0" .. idx)
    end
    return ""
end

---Gets transition phrase for intel broadcasts
---@param host string
---@return string
local function getTransition(host)
    local hosts = Constants.RadioHosts
    local idx = pickRandomIndex(2)

    if host == hosts.MARCUS then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_Transition_Marcus_0" .. idx)
    elseif host == hosts.JENNA then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_Transition_Jenna_0" .. idx)
    elseif host == hosts.RAY then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_Transition_Ray_0" .. idx)
    end
    return ""
end

---Gets paired small talk (segment 2 and 3) for intel broadcasts
---@param host string
---@param day number
---@return string seg2, string seg3
local function getSmallTalk(host, day)
    local phaseKey = getHostPhaseKey(host, day)
    local idx = pickRandomIndex(10)
    local idxStr = idx < 10 and ("0" .. idx) or tostring(idx)

    local seg2 = RadioFallback.ResolveText("IGUI_KnoxRelay_SmallTalk2_" .. phaseKey .. "_" .. idxStr)
    local seg3 = RadioFallback.ResolveText("IGUI_KnoxRelay_SmallTalk3_" .. phaseKey .. "_" .. idxStr)

    return seg2, seg3
end

---Gets No News content (segments 4-7) for intel broadcasts
---@param host string
---@param day number
---@return string seg4, string seg5, string seg6, string seg7
local function getNoNewsContent(host, day)
    local phaseKey = getHostPhaseKey(host, day)

    -- Segment 4 has 3 variations
    local idx4 = pickRandomIndex(3)
    local seg4 = RadioFallback.ResolveText("IGUI_KnoxRelay_NoNews4_" .. phaseKey .. "_0" .. idx4)

    -- Segments 5, 6, 7 have 10 variations each and must use the same index
    local idx567 = pickRandomIndex(10)
    local idxStr = idx567 < 10 and ("0" .. idx567) or tostring(idx567)

    local seg5 = RadioFallback.ResolveText("IGUI_KnoxRelay_NoNews5_" .. phaseKey .. "_" .. idxStr)
    local seg6 = RadioFallback.ResolveText("IGUI_KnoxRelay_NoNews6_" .. phaseKey .. "_" .. idxStr)
    local seg7 = RadioFallback.ResolveText("IGUI_KnoxRelay_NoNews7_" .. phaseKey .. "_" .. idxStr)

    return seg4, seg5, seg6, seg7
end

---Gets scene description for type
---@param sceneType string
---@return string
local function getSceneDescription(sceneType)
    local idx = pickRandomIndex(5)
    local key = "IGUI_KnoxRelay_Scene_" .. sceneType .. "_0" .. idx
    local text = RadioFallback.ResolveText(key)
    if text == key then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_Scene_Gunfight_01")
    end
    return text
end

---Gets scene warning for type
---@param sceneType string
---@return string
local function getSceneWarning(sceneType)
    local maxIdx = (sceneType == "Zombie") and 3 or 5
    local idx = pickRandomIndex(maxIdx)
    local key = "IGUI_KnoxRelay_Warning_" .. sceneType .. "_0" .. idx
    local text = RadioFallback.ResolveText(key)
    if text == key then
        return RadioFallback.ResolveText("IGUI_KnoxRelay_Warning_Gunfight_01")
    end
    return text
end

--//////////////////////////////////////////////////--
--          Special Broadcast Builders             --
--//////////////////////////////////////////////////--

---Builds Jenna's departure broadcast (Day 30)
---@param broadcastNum number 1, 2, or 3
---@return table
local function buildJennaDepartureBroadcast(broadcastNum)
    local broadcast = {}
    local prefix = "IGUI_KnoxRelay_Special_JennaDeparture_B" .. broadcastNum .. "S"
    local hostColor = (broadcastNum == 1) and Colors.JENNA or
        (broadcastNum == 2) and Colors.MARCUS or Colors.RAY

    local segCount = (broadcastNum == 1) and 9 or (broadcastNum == 2) and 9 or 8
    for i = 1, segCount do
        broadcast[#broadcast + 1] = line(RadioFallback.ResolveText(prefix .. i), hostColor)
    end
    return broadcast
end

---Builds Ray's death broadcast (Day 90)
---@param broadcastNum number 1 or 2
---@return table
local function buildRayDeathBroadcast(broadcastNum)
    local broadcast = {}
    local prefix = "IGUI_KnoxRelay_Special_RayDeath_B" .. broadcastNum .. "S"
    local hostColor = (broadcastNum == 1) and Colors.RAY or Colors.MARCUS

    for i = 1, 9 do
        local color = hostColor
        -- Make action/sound lines a different color
        if i == 5 or i == 9 then
            color = Colors.WARNING
        end
        broadcast[#broadcast + 1] = line(RadioFallback.ResolveText(prefix .. i), color)
    end
    return broadcast
end

--//////////////////////////////////////////////////--
--          Broadcast Builders                     --
--//////////////////////////////////////////////////--

---Builds a scripted morning show broadcast (8 segments)
---Segment 1: Welcome (reusable)
---Segment 2-3: Personal story (day-specific)
---Segment 4-6: Skill tip (day-specific)
---Segment 7: Wrap-up (reusable)
---Segment 8: Sign-off (reusable)
---@param host string Host name
---@param isSpecial boolean Is this a special broadcast (Day 30 or 90)
---@param day number Current game day
---@return table|nil Array of line entries
function ReactiveSE_RadioMessages.BuildMorningShow(host, isSpecial, day)
    local broadcast = {}
    local hostColor = getHostColor(host)
    local timeline = Constants.RadioTimeline
    local hosts = Constants.RadioHosts

    -- Handle special broadcasts
    if isSpecial then
        -- Day 30: Jenna's Departure
        if host == hosts.JENNA and day == timeline.JENNA_LAST_DAY then
            return buildJennaDepartureBroadcast(1)
        end
        -- Day 90: Ray's Death
        if host == hosts.RAY and day == timeline.RAY_LAST_DAY then
            return buildRayDeathBroadcast(1)
        end
    end

    -- Scripted 8-segment morning show
    -- Segment 1: Welcome (reusable)
    broadcast[#broadcast + 1] = line(getMorningWelcome(host), hostColor)

    -- Segments 2-6: Day-specific content
    -- Segments 2-3 are personal story (no XP)
    -- Segments 4-6 are skill tips (with XP effect)
    local s2, s3, s4, s5, s6 = getMorningDayContent(host, day)

    -- Check Sandbox Option for Morning Show XP
    local xpEffect = ""
    local config = Config.Get()
    if config.radio and config.radio.morningShowXP then
        xpEffect = getSkillXPEffect(host, day)
    end

    broadcast[#broadcast + 1] = line(s2, hostColor)           -- Story
    broadcast[#broadcast + 1] = line(s3, hostColor)           -- Story
    broadcast[#broadcast + 1] = line(s4, hostColor, xpEffect) -- Skill tip with XP
    broadcast[#broadcast + 1] = line(s5, hostColor, xpEffect) -- Skill tip with XP
    broadcast[#broadcast + 1] = line(s6, hostColor, xpEffect) -- Skill tip with XP

    -- Segment 7: Wrap-up (reusable)
    broadcast[#broadcast + 1] = line(getMorningWrapup(host), hostColor)

    -- Segment 8: Sign-off (reusable)
    broadcast[#broadcast + 1] = line(getMorningSignoff(host), hostColor)

    return broadcast
end

---Builds an intel report broadcast (8 segments)
---Segment 1: Welcome
---Segment 2-3: Small Talk (paired)
---Segment 4: Transition OR No News intro
---Segment 5: Scene description OR No News content
---Segment 6: Location OR No News content
---Segment 7: Warning OR No News content
---Segment 8: Sign-off
---@param host string Host name
---@param scene table|nil Scene data (nil for no news)
---@return table|nil Array of line entries
function ReactiveSE_RadioMessages.BuildIntelReport(host, scene)
    local broadcast = {}
    local hostColor = getHostColor(host)
    local day = getGameTime():getNightsSurvived() + 1
    local timeline = Constants.RadioTimeline

    -- Handle special Day 30 intel broadcasts (Marcus/Ray after Jenna leaves)
    if day == timeline.JENNA_LAST_DAY then
        local broadcastHour = getGameTime():getHour()
        if broadcastHour >= 13 then
            if host == Constants.RadioHosts.MARCUS then
                return buildJennaDepartureBroadcast(2)
            elseif host == Constants.RadioHosts.RAY then
                return buildJennaDepartureBroadcast(3)
            end
        end
    end

    -- Handle special Day 90 intel broadcasts (Marcus mourning)
    if day == timeline.RAY_LAST_DAY then
        local broadcastHour = getGameTime():getHour()
        if broadcastHour >= 13 then
            return buildRayDeathBroadcast(2)
        end
    end

    -- Regular 8-segment intel broadcast
    -- Segment 1: Welcome
    broadcast[#broadcast + 1] = line(getIntelWelcome(host, day), hostColor)

    -- Segment 2-3: Small Talk (paired)
    local seg2, seg3 = getSmallTalk(host, day)
    broadcast[#broadcast + 1] = line(seg2, hostColor)
    broadcast[#broadcast + 1] = line(seg3, hostColor)

    if scene then
        -- Scene report (segments 4-7)
        broadcast[#broadcast + 1] = line(getTransition(host), hostColor)
        broadcast[#broadcast + 1] = line(getSceneDescription(scene.type), Colors.SCENE)
        local locationText = RadioFallback.ResolveText("IGUI_KnoxRelay_Location", scene.x, scene.y)
        broadcast[#broadcast + 1] = line(locationText, Colors.SCENE)
        broadcast[#broadcast + 1] = line(getSceneWarning(scene.type), Colors.WARNING)
    else
        -- No News (segments 4-7)
        local seg4, seg5, seg6, seg7 = getNoNewsContent(host, day)
        broadcast[#broadcast + 1] = line(seg4, hostColor)
        broadcast[#broadcast + 1] = line(seg5, hostColor)
        broadcast[#broadcast + 1] = line(seg6, hostColor)
        broadcast[#broadcast + 1] = line(seg7, hostColor)
    end

    -- Segment 8: Sign-off
    broadcast[#broadcast + 1] = line(getIntelSignOff(host), hostColor)

    return broadcast
end

---Builds Jenna departure intel broadcast (Day 30, 13:00 or 19:00)
---@param host string "marcus" or "ray"
---@return table
function ReactiveSE_RadioMessages.BuildJennaDepartureIntel(host)
    -- B2 = Marcus at 13:00, B3 = Ray at 19:00
    if host == "marcus" then
        return buildJennaDepartureBroadcast(2)
    else
        return buildJennaDepartureBroadcast(3)
    end
end

---Builds Ray death intel broadcast (Day 90, 13:00 and 19:00)
---@return table
function ReactiveSE_RadioMessages.BuildRayDeathIntel()
    -- B2 = Marcus announcing Ray's death (same at both hours)
    return buildRayDeathBroadcast(2)
end

return ReactiveSE_RadioMessages
