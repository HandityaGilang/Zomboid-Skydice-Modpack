NMPortableMediaDropArbiter = NMPortableMediaDropArbiter or {}

local arbiter = NMPortableMediaDropArbiter

arbiter._zOrderSeq = arbiter._zOrderSeq or 0

local function probeEnabled()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe") == true
end

local function logProbe(tag, detail)
    if not (probeEnabled() and NMCore and NMCore.logChannel) then
        return
    end
    NMCore.logChannel("portableUiProbe", tostring(tag or "portable_ui"), tostring(detail or ""))
end

local function clampPlayerNum(playerNum)
    return tonumber(playerNum) or 0
end

local function getMousePoint()
    return getMouseX and getMouseX() or 0, getMouseY and getMouseY() or 0
end

local function pointInScreenRect(mx, my, rect)
    if type(rect) ~= "table" then
        return false
    end
    local x = tonumber(rect.x) or 0
    local y = tonumber(rect.y) or 0
    local w = tonumber(rect.w) or 0
    local h = tonumber(rect.h) or 0
    if w <= 0 or h <= 0 then
        return false
    end
    return mx >= x and mx < (x + w) and my >= y and my < (y + h)
end

local function zoneSummary(zone)
    if not zone then
        return "none"
    end
    return string.format(
        "%s:%s:item=%s:uuid=%s:z=%s:p=%s",
        tostring(zone.uiFamily or "unknown"),
        tostring(zone.zoneKind or "slot"),
        tostring(zone.itemId or ""),
        tostring(zone.uuid or ""),
        tostring(zone.zOrder or 0),
        tostring(zone.priority or 0)
    )
end

local function zonesToLine(zones)
    if type(zones) ~= "table" or #zones <= 0 then
        return "none"
    end
    local parts = {}
    for i = 1, #zones do
        parts[#parts + 1] = zoneSummary(zones[i])
    end
    return table.concat(parts, " | ")
end

local function sortZones(zones)
    table.sort(zones, function(a, b)
        local az = tonumber(a and a.zOrder) or 0
        local bz = tonumber(b and b.zOrder) or 0
        if az ~= bz then
            return az > bz
        end
        local ap = tonumber(a and a.priority) or 0
        local bp = tonumber(b and b.priority) or 0
        if ap ~= bp then
            return ap > bp
        end
        local af = tostring(a and a.uiFamily or "")
        local bf = tostring(b and b.uiFamily or "")
        if af ~= bf then
            return af < bf
        end
        local ai = tostring(a and a.itemId or "")
        local bi = tostring(b and b.itemId or "")
        if ai ~= bi then
            return ai < bi
        end
        return tostring(a and a.zoneKind or "") < tostring(b and b.zoneKind or "")
    end)
    return zones
end

local function collectImplementationZones(api, playerNum, dragItems)
    if not (api and api.collectOpenMediaIngressZones) then
        return {}
    end
    local ok, zones = pcall(api.collectOpenMediaIngressZones, playerNum, dragItems)
    if not ok or type(zones) ~= "table" then
        return {}
    end
    return zones
end

function arbiter.markWindowInteraction(window, uiFamily)
    if not window then
        return 0
    end
    arbiter._zOrderSeq = (tonumber(arbiter._zOrderSeq) or 0) + 1
    window._nmPortableUiZOrder = arbiter._zOrderSeq
    window._nmPortableUiFamily = tostring(uiFamily or window._nmPortableUiFamily or "")
    return window._nmPortableUiZOrder
end

function arbiter.getWindowZOrder(window)
    return tonumber(window and window._nmPortableUiZOrder) or 0
end

function arbiter.collectZones(playerNum, dragItems)
    local resolvedPlayerNum = clampPlayerNum(playerNum)
    local zones = {}
    local walkmanZones = collectImplementationZones(NMWalkmanWindow, resolvedPlayerNum, dragItems)
    local genericZones = collectImplementationZones(NMDeviceWindow, resolvedPlayerNum, dragItems)
    for i = 1, #walkmanZones do
        zones[#zones + 1] = walkmanZones[i]
    end
    for i = 1, #genericZones do
        zones[#zones + 1] = genericZones[i]
    end
    return zones
end

function arbiter.resolveWinningZone(playerNum, dragItems, mx, my)
    local mouseX = tonumber(mx)
    local mouseY = tonumber(my)
    if mouseX == nil or mouseY == nil then
        mouseX, mouseY = getMousePoint()
    end
    local zones = arbiter.collectZones(playerNum, dragItems)
    local eligible = {}
    local rejected = {}
    for i = 1, #zones do
        local zone = zones[i]
        local rect = zone and zone.rect or nil
        local accepted = zone
            and zone.window
            and zone.enabled == true
            and zone.visible == true
            and zone.canAccept == true
            and pointInScreenRect(mouseX, mouseY, rect)
        if accepted then
            eligible[#eligible + 1] = zone
        else
            rejected[#rejected + 1] = zone
        end
    end
    sortZones(eligible)
    local winner = eligible[1]
    logProbe(
        "drop_arbiter_resolve",
        string.format(
            "player=%s mouse=%s,%s winner=%s eligible=%s rejected=%s",
            tostring(clampPlayerNum(playerNum)),
            tostring(mouseX),
            tostring(mouseY),
            zoneSummary(winner),
            zonesToLine(eligible),
            zonesToLine(rejected)
        )
    )
    return winner, eligible, rejected
end

function arbiter.resolveOwningZone(playerNum, zoneKind, mx, my)
    local mouseX = tonumber(mx)
    local mouseY = tonumber(my)
    if mouseX == nil or mouseY == nil then
        mouseX, mouseY = getMousePoint()
    end
    local zones = arbiter.collectZones(playerNum, nil)
    local eligible = {}
    local rejected = {}
    for i = 1, #zones do
        local zone = zones[i]
        local rect = zone and zone.rect or nil
        local accepted = zone
            and zone.window
            and zone.enabled == true
            and zone.visible == true
            and zone.interactive == true
            and (zoneKind == nil or tostring(zone.zoneKind or "") == tostring(zoneKind or ""))
            and pointInScreenRect(mouseX, mouseY, rect)
        if accepted then
            eligible[#eligible + 1] = zone
        else
            rejected[#rejected + 1] = zone
        end
    end
    sortZones(eligible)
    local winner = eligible[1]
    logProbe(
        "slot_owner_resolve",
        string.format(
            "player=%s zone=%s mouse=%s,%s winner=%s eligible=%s rejected=%s",
            tostring(clampPlayerNum(playerNum)),
            tostring(zoneKind or ""),
            tostring(mouseX),
            tostring(mouseY),
            zoneSummary(winner),
            zonesToLine(eligible),
            zonesToLine(rejected)
        )
    )
    return winner, eligible, rejected
end

function arbiter.shouldWindowOwnZone(window, descriptor)
    if not window then
        return true
    end
    local zone = descriptor or {}
    local resolved = window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local playerNum = player and player.getPlayerNum and player:getPlayerNum() or window.playerNum or 0
    local winner = arbiter.resolveOwningZone(playerNum, zone.zoneKind)
    local accepted = winner ~= nil
        and winner.window == window
        and tostring(winner.zoneKind or "") == tostring(zone.zoneKind or "")
        and tostring(winner.itemId or "") == tostring(zone.itemId or zone.targetItemId or "")
        and tostring(winner.uuid or "") == tostring(zone.uuid or zone.targetUuid or "")
    logProbe(
        "slot_owner_consume",
        string.format(
            "ui=%s zone=%s itemId=%s uuid=%s accepted=%s winner=%s",
            tostring(zone.uiFamily or window._nmPortableUiFamily or "unknown"),
            tostring(zone.zoneKind or "slot"),
            tostring(zone.itemId or zone.targetItemId or ""),
            tostring(zone.uuid or zone.targetUuid or ""),
            tostring(accepted),
            zoneSummary(winner)
        )
    )
    return accepted, winner
end

function arbiter.shouldWindowConsumeDrop(window, descriptor)
    if not window then
        return true
    end
    local zone = descriptor or {}
    local resolved = window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local playerNum = player and player.getPlayerNum and player:getPlayerNum() or window.playerNum or 0
    local winner = arbiter.resolveWinningZone(playerNum, zone.dragItems)
    local accepted = winner ~= nil
        and winner.window == window
        and tostring(winner.zoneKind or "") == tostring(zone.zoneKind or "")
        and tostring(winner.itemId or "") == tostring(zone.itemId or zone.targetItemId or "")
        and tostring(winner.uuid or "") == tostring(zone.uuid or zone.targetUuid or "")
    logProbe(
        "drop_arbiter_consume",
        string.format(
            "ui=%s zone=%s itemId=%s uuid=%s accepted=%s winner=%s",
            tostring(zone.uiFamily or window._nmPortableUiFamily or "unknown"),
            tostring(zone.zoneKind or "slot"),
            tostring(zone.itemId or zone.targetItemId or ""),
            tostring(zone.uuid or zone.targetUuid or ""),
            tostring(accepted),
            zoneSummary(winner)
        )
    )
    return accepted, winner
end

return arbiter
