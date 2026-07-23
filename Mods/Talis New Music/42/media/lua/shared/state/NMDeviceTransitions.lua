-- Stateless transition rules applied to mutable device state records.
NMDeviceTransitions = NMDeviceTransitions or {}

local enforcePlayableByAction = {
    toggle_play = true,
    start_playback = true,
    power_on = true,
    power_off = true,
    toggle_power = true,
    eject_media = true,
    eject_battery = true,
    set_playback_mode = true,
    track_finished = true
}

function NMDeviceTransitions.apply(profile, state, action, payload)
    if not profile or not state then
        return false, "invalid_state", nil
    end
    payload = payload or {}
    action = tostring(action or "")

    local ops = {}
    local changed, reason = NMTransitionActionHandlers.apply(profile, state, action, payload, ops)
    if reason then
        return false, reason, nil
    end

    if enforcePlayableByAction[action] and NMTransitionCommon.enforcePlayableState(profile, state, payload) then
        changed = true
    end
    return changed, nil, ops
end



