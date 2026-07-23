require "ISUI/ISButton"
NMTransportButtonRow = NMTransportButtonRow or {}

local BTN_W = 39
local BTN_H = 29
local BTN_GAP = 13
local FLICK_MS = 250
local ORDER = { "repeat", "stop", "play", "prev", "next", "mute" }
local UI_TEXTURE_ROOT = "media/textures/UI/"

local BASE_TEXTURES = {
    ["in"] = "UI_NM_ButtonBaseIn.png",
    ["out"] = "UI_NM_ButtonBaseOut.png"
}

local ICON_TEXTURES = {
    play = "UI_NM_Play.png",
    stop = "UI_NM_Stop.png",
    prev = "UI_NM_Prev.png",
    next = "UI_NM_Next.png",
    repeat_none = "UI_NM_RepeatNone.png",
    repeat_song = "UI_NM_RepeatSong.png",
    repeat_album = "UI_NM_RepeatAlbum.png",
    sound_on = "UI_NM_SoundOn.png",
    sound_off = "UI_NM_SoundOff.png"
}

local textureCache = {}

local function getUiTexture(fileName)
    if not fileName or not getTexture then
        return nil
    end
    local path = UI_TEXTURE_ROOT .. tostring(fileName)
    local cached = textureCache[path]
    if cached ~= nil then
        return cached
    end
    local tex = getTexture(path)
    textureCache[path] = tex or false
    return tex
end

local function drawButtonTexture(button, tex)
    if not (button and tex and button.drawTextureScaled) then
        return false
    end
    button:drawTextureScaled(tex, 0, 0, BTN_W, BTN_H, 1.0, 1.0, 1.0, 1.0)
    return true
end

local function getResolvedContext(window)
    if not window then
        return nil
    end
    if window.resolveContextCached then
        return window:resolveContextCached()
    end
    return window.resolveContext and window:resolveContext() or nil
end

local function resolveTrackCount(state)
    if not state or not state.mediaFullType or not NMMusic or not NMMusic.resolveTracks then
        return 0
    end
    local ok, resolved = pcall(NMMusic.resolveTracks, state.mediaFullType)
    if not ok or type(resolved) ~= "table" or type(resolved.tracks) ~= "table" then
        return 0
    end
    return #resolved.tracks
end

local function nowMs(window)
    return (window and tonumber(window._nmFrameNowMs))
        or (getTimestampMs and getTimestampMs())
        or (getTimeInMillis and getTimeInMillis())
        or 0
end

function NMTransportButtonRow.buildRenderState(window, frame)
    local resolved = frame and frame.resolved or getResolvedContext(window)
    local state = resolved and resolved.state or nil
    local policy = tostring(state and state.playbackPolicy or "autoplay")
    local repeatIcon = "repeat_none"
    if policy == "loop_song" then
        repeatIcon = "repeat_song"
    elseif policy == "loop_album" then
        repeatIcon = "repeat_album"
    end
    local muted = state and state.isMuted == true
    local playing = state and state.isPlaying == true
    local buttons = {}
    local currentNowMs = frame and frame.nowMs or nowMs(window)
    for i = 1, #ORDER do
        local role = ORDER[i]
        local baseState = "out"
        if role == "play" then
            baseState = playing and "in" or "out"
        elseif role == "stop" then
            baseState = playing and "out" or "in"
        elseif role == "mute" then
            baseState = muted and "in" or "out"
        end
        local iconKey = role
        if role == "repeat" then
            iconKey = repeatIcon
        elseif role == "mute" then
            iconKey = muted and "sound_off" or "sound_on"
        end
        local tooltip = ""
        if role == "repeat" then
            if iconKey == "repeat_song" then
                tooltip = NMTranslations.ui("RepeatSong", "Repeat Song")
            elseif iconKey == "repeat_album" then
                tooltip = NMTranslations.ui("RepeatAlbum", "Repeat Album")
            else
                tooltip = NMTranslations.ui("RepeatNone", "Repeat None")
            end
        elseif role == "mute" then
            tooltip = muted and NMTranslations.ui("Unmute", "Unmute") or NMTranslations.ui("Mute", "Mute")
        elseif role == "play" then
            tooltip = NMTranslations.ui("PlaySong", "Play Song")
        elseif role == "stop" then
            tooltip = NMTranslations.ui("StopSong", "Stop Song")
        elseif role == "prev" then
            tooltip = NMTranslations.ui("PreviousTrack", "Previous Track")
        elseif role == "next" then
            tooltip = NMTranslations.ui("NextTrack", "Next Track")
        end
        local btn = window and window.transportRow and window.transportRow.buttons and window.transportRow.buttons[i] or nil
        local flickActive = btn and tonumber(btn._nmFlickUntil or 0) > currentNowMs or false
        local style = baseState
        if (role == "repeat" or role == "prev" or role == "next") and flickActive then
            style = "in"
        end
        buttons[role] = {
            role = role,
            baseState = baseState,
            style = style,
            iconKey = iconKey,
            tooltip = tooltip,
            baseTexture = BASE_TEXTURES[style] or BASE_TEXTURES.out,
            iconTexture = ICON_TEXTURES[iconKey],
            flickActive = flickActive,
        }
    end
    return {
        state = state,
        muted = muted,
        playing = playing,
        repeatIcon = repeatIcon,
        buttons = buttons,
    }
end

local function dispatch(window, action, args)
    if not (window and window.dispatch) then
        return false
    end
    local ok = window:dispatch(action, args or {})
    return ok == true
end

local function playButtonClick(window)
    local soundName = "NM_ButtonClick"
    local vol = 0.8
    local resolved = getResolvedContext(window)
    local playerObj = resolved and resolved.player or nil

    local function isValidSoundId(soundId)
        if soundId == nil then
            return false
        end
        local n = tonumber(soundId)
        if n and n == 0 then
            return false
        end
        return true
    end

    if playerObj and playerObj.getEmitter then
        local okEmitter, emitter = pcall(playerObj.getEmitter, playerObj)
        if okEmitter and emitter then
            local okPlay, soundId = false, nil
            if emitter.playSoundImpl then
                okPlay, soundId = pcall(emitter.playSoundImpl, emitter, soundName, nil)
            end
            if (not okPlay or not isValidSoundId(soundId)) and emitter.playSound then
                okPlay, soundId = pcall(emitter.playSound, emitter, soundName)
            end
            if okPlay and isValidSoundId(soundId) then
                if emitter.setVolume then
                    pcall(emitter.setVolume, emitter, soundId, vol)
                end
                return
            end
        end
    end
    if playerObj and playerObj.playSoundLocal then
        local ok = pcall(playerObj.playSoundLocal, playerObj, soundName)
        if ok then
            return
        end
    end
    local sm = getSoundManager and getSoundManager() or nil
    if sm and sm.playUISound then
        pcall(sm.playUISound, sm, soundName)
    end
end

local function makeButton(window, x, y, role)
    local btn = ISButton:new(x, y, BTN_W, BTN_H, "", window, function() end)
    btn:initialise()
    btn:instantiate()
    btn.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    btn.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    btn.backgroundColorMouseOver = { r = 0, g = 0, b = 0, a = 0 }
    btn.backgroundColorEnabled = { r = 0, g = 0, b = 0, a = 0 }
    btn.enable = true
    btn._nmRole = role
    btn._nmFlickUntil = 0
    window:addChild(btn)
    return btn
end

local function handlePress(window, role)
    local renderState = window and window.getRenderState and window:getRenderState("transport") or nil
    if role == "repeat" then
        local policy = tostring(renderState and renderState.state and renderState.state.playbackPolicy or "autoplay")
        local nextPolicy = "autoplay"
        if policy == "autoplay" then
            nextPolicy = "loop_song"
        elseif policy == "loop_song" then
            nextPolicy = "loop_album"
        else
            nextPolicy = "autoplay"
        end
        return dispatch(window, "set_playback_policy", { playbackPolicy = nextPolicy })
    end
    local state = renderState and renderState.state or nil
    if role == "prev" then
        return dispatch(window, "prev_track", { trackCount = resolveTrackCount(state) })
    end
    if role == "next" then
        return dispatch(window, "next_track", { trackCount = resolveTrackCount(state) })
    end
    return false
end

local function handleHold(window, role)
    local renderState = window and window.getRenderState and window:getRenderState("transport") or nil
    local state = renderState and renderState.state or nil
    if role == "play" then
        return dispatch(window, "start_playback", { isPlaying = true, trackCount = resolveTrackCount(state) })
    end
    if role == "stop" then
        return dispatch(window, "stop_playback", { isPlaying = false, trackCount = resolveTrackCount(state) })
    end
    if role == "mute" then
        local muted = state and state.isMuted == true
        return dispatch(window, "toggle_mute", { isMuted = not muted, muteReason = "manual" })
    end
    return false
end

local function bindRender(window, btn)
    local role = btn._nmRole
    btn.render = function(self)
        local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(window) or nil
        self:setTitle("")
        local renderState = window.getRenderState and window:getRenderState("transport") or nil
        local buttonState = renderState and renderState.buttons and renderState.buttons[role] or nil
        local baseTex = getUiTexture(buttonState and buttonState.baseTexture or BASE_TEXTURES.out)
        local iconTex = getUiTexture(buttonState and buttonState.iconTexture or ICON_TEXTURES[role])
        drawButtonTexture(self, baseTex)
        drawButtonTexture(self, iconTex)

        self.tooltip = buttonState and buttonState.tooltip or ""
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(window, "widget.transport.render", perfStart)
        end
    end
end

local function bindInput(window, btn)
    local role = btn._nmRole
    btn.onMouseDown = function(self, x, y)
        return true
    end
    btn.onMouseUp = function(self, x, y)
        local ok = false
        if role == "repeat" or role == "prev" or role == "next" then
            self._nmFlickUntil = nowMs(window) + FLICK_MS
            ok = handlePress(window, role)
        else
            ok = handleHold(window, role)
        end
        playButtonClick(window)
        return true
    end
end

function NMTransportButtonRow.getSize()
    local w = (#ORDER * BTN_W) + ((#ORDER - 1) * BTN_GAP)
    return w, BTN_H
end

function NMTransportButtonRow.attach(window, x, y)
    local buttons = {}
    for i = 1, #ORDER do
        local role = ORDER[i]
        local bx = x + ((i - 1) * (BTN_W + BTN_GAP))
        local btn = makeButton(window, bx, y, role)
        bindRender(window, btn)
        bindInput(window, btn)
        buttons[#buttons + 1] = btn
    end
    return {
        buttons = buttons,
        x = x,
        y = y,
        width = (#ORDER * BTN_W) + ((#ORDER - 1) * BTN_GAP),
        height = BTN_H
    }
end
