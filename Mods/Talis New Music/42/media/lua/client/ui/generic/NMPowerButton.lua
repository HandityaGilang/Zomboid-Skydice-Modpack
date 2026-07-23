require "ISUI/ISButton"
NMPowerButton = NMPowerButton or {}

local function playPowerClick(window, isTurningOn)
    local soundName = isTurningOn and "NM_ButtonClick" or "NM_ButtonClick2"
    local playerObj = window and window.resolveContextCached and window:resolveContextCached()
        or (window and window.resolveContext and window:resolveContext() or nil)
    playerObj = playerObj and playerObj.player or nil
    local function isValidSoundId(soundId)
        if soundId == nil then return false end
        local n = tonumber(soundId)
        if n and n == 0 then return false end
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
                    pcall(emitter.setVolume, emitter, soundId, 0.8)
                end
                return
            end
        end
    end
    if playerObj and playerObj.playSoundLocal then
        local ok = pcall(playerObj.playSoundLocal, playerObj, soundName)
        if ok then return end
    end
    local sm = getSoundManager and getSoundManager() or nil
    if sm and sm.playUISound then
        local ok = pcall(sm.playUISound, sm, soundName)
        if ok then return end
        pcall(sm.playUISound, sm, "UISelectListItem")
    end
end

local function getLayerOrder(state)
    local order = { "base01", "base02", "base03" }
    if state == "off" then
        order[#order + 1] = "off01"
        order[#order + 1] = "off02"
        order[#order + 1] = "off03"
        order[#order + 1] = "off04"
    else
        order[#order + 1] = "on01"
        order[#order + 1] = "on02"
        order[#order + 1] = "on03"
        order[#order + 1] = (state == "on_power") and "on04_power" or "on04_no_power"
    end
    return order
end

local function drawPowerSwitchIcon(button, state)
    if type(NMPowerSwitchVectors) ~= "table" or type(NMPowerSwitchVectors.layers) ~= "table" then
        return
    end
    if type(NMVectorDraw) ~= "table" or type(NMVectorDraw.drawShape) ~= "function" then
        return
    end

    local w = tonumber(button and button.width) or 0
    local h = tonumber(button and button.height) or 0
    if w <= 0 or h <= 0 then return end
    local size = math.max(8, math.floor((math.min(w, h) * 0.98) + 0.5))
    local left = math.floor((w - size) * 0.5 + 0.5)
    local top = math.floor((h - size) * 0.5 + 0.5)
    local drawState = (state == "off") and "off" or ((state == "on_power") and "on_power" or "on_no_power")
    local order = getLayerOrder(drawState)
    for i = 1, #order do
        local id = order[i]
        local layer = NMPowerSwitchVectors.layers[id]
        if layer and layer.points and layer.color then
            NMVectorDraw.drawShape(button, layer.points, layer.color, left, top, size, NMPowerSwitchVectors.viewBox, NMPowerSwitchVectors.bounds, size)
        end
    end
end

function NMPowerButton.resolvePowerState(profile, state, externalPowerAvailable)
    if not state or state.isOn ~= true then
        return "off"
    end
    local needsBattery = NMDeviceProfiles.supportsBattery and NMDeviceProfiles.supportsBattery(profile)
    if needsBattery then
        local hasBatteryPower = state.batteryPresent == true and (tonumber(state.batteryCharge) or 0) > 0
        if hasBatteryPower then
            return "on_power"
        end
        return "on_no_power"
    end
    if NMDeviceProfiles.requiresExternalPower and NMDeviceProfiles.requiresExternalPower(profile) then
        if externalPowerAvailable == true then
            return "on_power"
        end
        return "on_no_power"
    end
    if state.isOn == true then
        return "on_power"
    end
    return "off"
end

function NMPowerButton.buildRenderState(window, frame)
    local resolved = frame and frame.resolved or (window and window.resolveContextCached and window:resolveContextCached()) or nil
    local stateToken = "off"
    if resolved then
        local externalPowerAvailable = nil
        if NMDeviceProfiles.requiresExternalPower and NMDeviceProfiles.requiresExternalPower(resolved.profile) then
            externalPowerAvailable = NMInventoryHelpers
                and NMInventoryHelpers.resolveExternalPowerAvailable
                and NMInventoryHelpers.resolveExternalPowerAvailable(resolved.player, resolved.item, resolved.profile)
        end
        stateToken = NMPowerButton.resolvePowerState(resolved.profile, resolved.state, externalPowerAvailable)
    end
    local tooltip = NMTranslations.ui("PowerOff", "Power: OFF")
    if stateToken == "on_power" then
        tooltip = NMTranslations.ui("PowerOn", "Power: ON")
    elseif stateToken == "on_no_power" then
        tooltip = NMTranslations.ui("PowerOnNoPower", "Power: ON (No Power)")
    end
    return {
        stateToken = stateToken,
        tooltip = tooltip,
    }
end

function NMPowerButton.attach(window, x, y, size)
    local btn = ISButton:new(x, y, size, size, "", window, function() end)
    btn:initialise()
    btn:instantiate()
    window:addChild(btn)
    btn.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    btn.backgroundColorMouseOver = { r = 0, g = 0, b = 0, a = 0 }
    btn.backgroundColorClicked = { r = 0, g = 0, b = 0, a = 0 }
    btn.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    btn.borderColorMouseOver = { r = 0, g = 0, b = 0, a = 0 }
    btn.borderColorClicked = { r = 0, g = 0, b = 0, a = 0 }
    btn.backgroundColorEnabled = { r = 0, g = 0, b = 0, a = 0 }
    btn.borderColorEnabled = { r = 0, g = 0, b = 0, a = 0 }
    btn.onMouseUp = function(selfBtn, xArg, yArg)
        if not selfBtn:getIsVisible() then
            return true
        end
        local process = (selfBtn.pressed == true)
        selfBtn.pressed = false
        if selfBtn.enable and (process or selfBtn.allowMouseUpProcessing) then
            local win = selfBtn.target
            local resolved = win and win.resolveContextCached and win:resolveContextCached()
                or (win and win.resolveContext and win:resolveContext() or nil)
            local currentIsOn = resolved and resolved.state and resolved.state.isOn == true
            local nextIsOn = not currentIsOn
            if win then
                win:dispatch("toggle_power", { isOn = nextIsOn })
                playPowerClick(win, nextIsOn)
            end
        end
        return true
    end

    local baseRender = btn.render
    btn.render = function(self)
        self:setTitle("")
        baseRender(self)
        local renderState = window.getRenderState and window:getRenderState("power") or nil
        local stateToken = renderState and renderState.stateToken or "off"
        drawPowerSwitchIcon(self, stateToken)
        self.tooltip = renderState and renderState.tooltip or NMTranslations.ui("PowerOff", "Power: OFF")
    end

    return btn
end
