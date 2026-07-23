
NMDeviceUI = NMDeviceUI or {}

local function useFancyWalkmanUI()
    if NMRuntimeConfig and NMRuntimeConfig.getFancyUIEnabled then
        return NMRuntimeConfig.getFancyUIEnabled() == true
    end
    return true
end

local function portableUiImplementations()
    local out = {}
    if NMWalkmanWindow then
        out[#out + 1] = { name = "walkman", api = NMWalkmanWindow }
    end
    if NMDeviceWindow then
        out[#out + 1] = { name = "generic", api = NMDeviceWindow }
    end
    return out
end

local function logPortableUiDispatch(actionName, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe")) then
        return
    end
    NMCore.logChannel("portableUiProbe", "portable_ui_" .. tostring(actionName or "unknown"), tostring(detail or ""))
end

local function inspectImplementationWindow(entry, playerNum)
    local api = entry and entry.api or nil
    if not (api and api.inspectOpenItemWindowTarget) then
        return nil
    end
    local inspected = api.inspectOpenItemWindowTarget(playerNum)
    if inspected then
        inspected.uiFamily = tostring(entry.name or "unknown")
    end
    return inspected
end

local function snapshotsToLine(snapshots)
    if type(snapshots) ~= "table" or #snapshots <= 0 then
        return "none"
    end
    local parts = {}
    for i = 1, #snapshots do
        local snap = snapshots[i]
        parts[#parts + 1] = string.format(
            "%s[player=%s itemId=%s uuid=%s hasRef=%s timed=%s pending=%s awaitInsert=%s awaitEject=%s]",
            tostring(snap.uiFamily or "unknown"),
            tostring(snap.playerNum or 0),
            tostring(snap.itemId or ""),
            tostring(snap.uuid or ""),
            tostring(snap.hasItemRef == true),
            tostring(snap.mediaTimedAction or ""),
            tostring(snap.pendingMediaFullType or ""),
            tostring(snap.awaitingMediaInsert == true),
            tostring(snap.awaitingMediaEject == true)
        )
    end
    return table.concat(parts, " ")
end

function NMDeviceUI.openForItem(playerNum, item)
    local profile = NMDeviceProfiles and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(item) or nil
    if profile and tostring(profile.deviceType or "") == "walkman" and useFancyWalkmanUI() then
        return NMWalkmanWindow.openForItem(playerNum, item)
    end
    return NMDeviceWindow.openForItem(playerNum, item)
end

function NMDeviceUI.openForVehicle(playerNum, vehicle, part)
    return NMDeviceWindow.openForVehicle(playerNum, vehicle, part)
end

function NMDeviceUI.closeForItem(playerNum, itemId, uuid)
    local closed = false
    local before = NMDeviceUI.inspectOpenPortableWindows(playerNum)
    local implementations = portableUiImplementations()
    for i = 1, #implementations do
        local entry = implementations[i]
        local api = entry.api
        local accepted = api and api.closeOpenForItemTarget and api.closeOpenForItemTarget(playerNum, itemId, uuid) == true or false
        logPortableUiDispatch(
            "close_dispatch",
            string.format(
                "impl=%s player=%s itemId=%s uuid=%s accepted=%s",
                tostring(entry.name or "unknown"),
                tostring(playerNum or 0),
                tostring(itemId or ""),
                tostring(uuid or ""),
                tostring(accepted)
            )
        )
        closed = accepted or closed
    end
    local after = NMDeviceUI.inspectOpenPortableWindows(playerNum)
    logPortableUiDispatch(
        "close_snapshot",
        string.format(
            "player=%s before=%s after=%s",
            tostring(playerNum or 0),
            snapshotsToLine(before),
            snapshotsToLine(after)
        )
    )
    return closed
end

function NMDeviceUI.invalidateOpenItemWindow(itemId, uuid)
    local invalidated = false
    local before = NMDeviceUI.inspectOpenPortableWindows(0)
    local implementations = portableUiImplementations()
    for i = 1, #implementations do
        local entry = implementations[i]
        local api = entry.api
        local accepted = api and api.invalidateOpenItemWindow and api.invalidateOpenItemWindow(itemId, uuid) == true or false
        logPortableUiDispatch(
            "invalidate_dispatch",
            string.format(
                "impl=%s itemId=%s uuid=%s accepted=%s",
                tostring(entry.name or "unknown"),
                tostring(itemId or ""),
                tostring(uuid or ""),
                tostring(accepted)
            )
        )
        invalidated = accepted or invalidated
    end
    local after = NMDeviceUI.inspectOpenPortableWindows(0)
    logPortableUiDispatch(
        "invalidate_snapshot",
        string.format(
            "itemId=%s uuid=%s before=%s after=%s",
            tostring(itemId or ""),
            tostring(uuid or ""),
            snapshotsToLine(before),
            snapshotsToLine(after)
        )
    )
    return invalidated
end

function NMDeviceUI.rebindOpenPortableItemWindow(itemId, uuid)
    local rebound = false
    local before = NMDeviceUI.inspectOpenPortableWindows(0)
    local implementations = portableUiImplementations()
    for i = 1, #implementations do
        local entry = implementations[i]
        local api = entry.api
        local accepted = api and api.rebindOpenPortableItemWindow and api.rebindOpenPortableItemWindow(itemId, uuid) == true or false
        logPortableUiDispatch(
            "rebind_dispatch",
            string.format(
                "impl=%s itemId=%s uuid=%s accepted=%s",
                tostring(entry.name or "unknown"),
                tostring(itemId or ""),
                tostring(uuid or ""),
                tostring(accepted)
            )
        )
        rebound = accepted or rebound
    end
    local after = NMDeviceUI.inspectOpenPortableWindows(0)
    logPortableUiDispatch(
        "rebind_snapshot",
        string.format(
            "itemId=%s uuid=%s before=%s after=%s",
            tostring(itemId or ""),
            tostring(uuid or ""),
            snapshotsToLine(before),
            snapshotsToLine(after)
        )
    )
    return rebound
end

function NMDeviceUI.inspectOpenItemWindowTarget(playerNum)
    local implementations = portableUiImplementations()
    for i = 1, #implementations do
        local entry = implementations[i]
        local api = entry.api
        local inspected = api and api.inspectOpenItemWindowTarget and api.inspectOpenItemWindowTarget(playerNum) or nil
        if inspected then
            inspected.uiFamily = tostring(entry.name or "unknown")
            return inspected
        end
    end
    return nil
end

function NMDeviceUI.inspectOpenPortableWindows(playerNum)
    local implementations = portableUiImplementations()
    local out = {}
    for i = 1, #implementations do
        local inspected = inspectImplementationWindow(implementations[i], playerNum)
        if inspected then
            out[#out + 1] = inspected
        end
    end
    return out
end
